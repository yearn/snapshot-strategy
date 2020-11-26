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
min_bag: public(uint256)  # 1 YFI to enter
ape_out: public(uint256)  # 30 days falloff
activation: public(uint256)
yfi: ERC20
ygov: ERC20
yyfi: Vault
proxy_registry: DSProxyRegistry
cdp_manager: DssCdpManager
vat: Vat
ilk: bytes32


@external
def __init__():
    self.bouncer = msg.sender
    self.activation = block.timestamp
    self.min_bag = 10 ** 18
    self.ape_out = 86400 * 30
    self.yfi = ERC20(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e)
    self.ygov = ERC20(0xBa37B002AbaFDd8E89a1995dA52740bbC013D992)
    self.yyfi = Vault(0xBA2E7Fed597fd0E3e70f5130BcDbbFE06bB94fe1)
    self.proxy_registry = DSProxyRegistry(0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4)
    self.cdp_manager = DssCdpManager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39)
    self.vat = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B)
    yfi_a: Bytes[32] = b"YFI-A"
    self.ilk = convert(yfi_a, bytes32)


@external
def set_guest(guest: address, invited: bool):
    """
    Invite of kick guests from the party.
    """
    assert msg.sender == self.bouncer
    self.guests[guest] = invited


@external
def set_min_bag(new_min_bag: uint256):
    """
    Set the minimum bag size to bypass the guest list.
    """
    assert msg.sender == self.bouncer
    self.min_bag = new_min_bag


@external
def set_bouncer(new_bouncer: address):
    """
    Replace bouncer role.
    """
    assert msg.sender == self.bouncer
    self.bouncer = new_bouncer


@view
@internal
def _yfi_in_makerdao(user: address) -> uint256:
    proxy: address = self.proxy_registry.proxies(user)
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
def _total_yfi(user: address) -> uint256:
    return (
        self.yfi.balanceOf(user)
        + self.ygov.balanceOf(user)
        + self.yyfi.balanceOf(user) * self.yyfi.getPricePerFullShare() / 10 ** 18
        + self._yfi_in_makerdao(user)
    )


@view
@internal
def _time_factor(bag: uint256) -> uint256:
    return bag - min(bag * (block.timestamp - self.activation) / self.ape_out, bag)


@view
@external
def total_yfi(user: address) -> uint256:
    """
    Total YFI in wallet + ygov + vault + makerdao.
    """
    return self._total_yfi(user)


@view
@external
def yfi_in_makerdao(user: address) -> uint256:
    return self._yfi_in_makerdao(user)


@view
@external
def entrance_cost() -> uint256:
    return self._time_factor(self.min_bag)


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
    return self._total_yfi(guest) >= self._time_factor(self.min_bag)
