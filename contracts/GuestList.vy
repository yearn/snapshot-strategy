# @version 0.2.7
from vyper.interfaces import ERC20


struct List:
    prev: uint256
    next: uint256


struct Urn:
    ink: uint256
    art: uint256


interface Vault:
    def balanceOf(user: address) -> uint256: view
    def getPricePerFullShare() -> uint256: view


interface DSProxyRegistry:
    def proxies(user: address) -> address: view


interface DssCdpManager:
    def count(user: address) -> uint256: view
    def first(user: address) -> uint256: view
    def list(cdp: uint256) -> List: view
    def ilks(cdp: uint256) -> bytes32: view
    def urns(cdp: uint256) -> address: view


interface Vat:
    def urns(ilk: bytes32, user: address) -> Urn: view


bouncer: public(address)
guests: public(HashMap[address, bool])
min_bag: public(uint256)
ape_out: public(uint256)
activation: public(uint256)
yfi: ERC20
ygov: ERC20
yyfi: Vault
proxy_registry: DSProxyRegistry
cdp_manager: DssCdpManager
vat: Vat
ilk: bytes32
weth: ERC20
uni_pairs: address[2]


@external
def __init__():
    self.bouncer = msg.sender
    self.activation = block.timestamp
    # constants
    self.min_bag = 10 ** 18  # 1 YFI to enter
    self.ape_out = 30 * 86400  # 30 days falloff
    # tokens
    self.weth = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
    self.yfi = ERC20(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e)
    self.ygov = ERC20(0xBa37B002AbaFDd8E89a1995dA52740bbC013D992)
    self.yyfi = Vault(0xBA2E7Fed597fd0E3e70f5130BcDbbFE06bB94fe1)
    # makerdao
    self.proxy_registry = DSProxyRegistry(0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4)
    self.cdp_manager = DssCdpManager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39)
    self.vat = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B)
    yfi_a: Bytes[32] = b"YFI-A"
    self.ilk = convert(yfi_a, bytes32)
    # liquidity providers
    self.uni_pairs = [
        0x2fDbAdf3C4D5A8666Bc06645B8358ab803996E28,  # Uniswap YFI/WETH
        0x088ee5007C98a9677165D78dD2109AE4a3D04d0C,  # Sushiswap YFI/WETH
    ]


@external
def set_guest(guest: address, invited: bool):
    """
    Invite of kick guests from the party.
    """
    assert msg.sender == self.bouncer
    self.guests[guest] = invited


@external
def set_bouncer(new_bouncer: address):
    """
    Replace bouncer role.
    """
    assert msg.sender == self.bouncer
    self.bouncer = new_bouncer


@view
@internal
def yfi_in_vault(user: address) -> uint256:
    return self.yyfi.balanceOf(user) * self.yyfi.getPricePerFullShare() / 10 ** 18


@view
@internal
def yfi_in_makerdao(user: address) -> uint256:
    proxy: address = self.proxy_registry.proxies(user)
    if proxy == ZERO_ADDRESS:
        return 0
    cdp: uint256 = self.cdp_manager.first(proxy)
    urn: address = ZERO_ADDRESS
    total: uint256 = 0
    for i in range(100):
        if cdp == 0:
            break
        if self.cdp_manager.ilks(cdp) == self.ilk:
            urn = self.cdp_manager.urns(cdp)
            total += self.vat.urns(self.ilk, urn).ink        
        cdp = self.cdp_manager.list(cdp).next
    return total


@view
@internal
def yfi_in_liquidity_pools(user: address) -> uint256:
    total: uint256 = 0
    for pair in self.uni_pairs:
        total += self.yfi.balanceOf(pair) * ERC20(pair).balanceOf(user) / ERC20(pair).totalSupply()
    return total


@view
@internal
def _total_yfi(user: address) -> uint256:
    return (
        self.yfi.balanceOf(user)
        + self.ygov.balanceOf(user)
        + self.yfi_in_vault(user)
        + self.yfi_in_makerdao(user)
        + self.yfi_in_liquidity_pools(user)
    )


@view
@internal
def _entrance_cost() -> uint256:
    elapsed: uint256 = min(block.timestamp - self.activation, self.ape_out)
    return self.min_bag - self.min_bag * elapsed / self.ape_out


@view
@external
def total_yfi(user: address) -> uint256:
    """
    Total YFI in wallet + ygov + vault + makerdao + uniswap lp + sushiswap lp.
    """
    return self._total_yfi(user)


@view
@external
def entrance_cost() -> uint256:
    return self._entrance_cost()


@view
@external
def authorized(guest: address, amount: uint256) -> bool:
    """
    Check if a user with a bag of certain size is allowed to the party.
    """
    if self.guests[guest]:
        return True    
    if block.timestamp > self.activation + self.ape_out:
        return True
    return self._total_yfi(guest) >= self._entrance_cost()
