# @version 0.2.16
# @author banteg
# @notice Calculate voting power from productive YFI
from vyper.interfaces import ERC20

struct VotingBalances:
    wallet: uint256
    vault: uint256
    bancor: uint256
    balancer: uint256
    uniswap: uint256
    sushiswap: uint256
    makerdao: uint256
    unit: uint256


struct List:
    prev: uint256
    next: uint256


struct Urn:
    ink: uint256
    art: uint256


struct ProtectedLiquidity:
    provider: address
    poolToken: address
    reserveToken: address
    poolAmount: uint256
    reserveAmount: uint256
    reserveRateN: uint256
    reserveRateD: uint256
    time: uint256


struct UserInfo:
    amount: uint256
    rewardDebt: uint256


struct PoolTokenInfo:
    cash: uint256
    managed: uint256
    lastChangeBlock: uint256
    assetManager: address


interface Registry:
    def numVaults(token: address) -> uint256: view
    def vaults(token: address, n: uint256) -> address: view


interface Vault:
    def pricePerShare() -> uint256: view


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


interface Bancor:
    def protectedLiquidityCount(provider: address) -> uint256: view
    def protectedLiquidityId(provider: address, index: uint256) -> uint256: view
    def protectedLiquidity(_id: uint256) -> ProtectedLiquidity: view


interface MasterChef:
    def userInfo(pid: uint256, user: address) -> UserInfo: view


interface Unit:
    def collaterals(token: address, user: address) -> uint256: view


interface BalancerVault:
    def getPool(pool_id: bytes32) -> (address, uint256): view
    def getPoolTokenInfo(pool_id: bytes32, token: address) -> PoolTokenInfo: view


yfi: constant(address) = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e
registry: constant(address) = 0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804
balancer_v2: constant(address) = 0xBA12222222228d8Ba445958a75a0704d566BF2C8
masterchef: constant(address) = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd
sushiswap: constant(address) = 0x088ee5007C98a9677165D78dD2109AE4a3D04d0C
uniswap: constant(address) = 0x2fDbAdf3C4D5A8666Bc06645B8358ab803996E28
bancor: constant(address) = 0xf5FAB5DBD2f3bf675dE4cB76517d4767013cfB55
unit: constant(address) = 0xb1cFF81b9305166ff1EFc49A129ad2AfCd7BCf19
proxy_registry: constant(address) = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4
cdp_manager: constant(address) = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39
vat: constant(address) = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B


@view
@internal
def makerdao_collateral(user: address) -> uint256:
    yfi_a: bytes32 = 0x5946492d41000000000000000000000000000000000000000000000000000000
    proxy: address = DSProxyRegistry(proxy_registry).proxies(user)
    if proxy == ZERO_ADDRESS:
        return 0
    cdp: uint256 = DssCdpManager(cdp_manager).first(proxy)
    urn: address = ZERO_ADDRESS
    total: uint256 = 0
    for i in range(100):
        if cdp == 0:
            break
        if DssCdpManager(cdp_manager).ilks(cdp) == yfi_a:
            urn = DssCdpManager(cdp_manager).urns(cdp)
            total += Vat(vat).urns(yfi_a, urn).ink
        cdp = DssCdpManager(cdp_manager).list(cdp).next
    return total


@view
@internal
def lp_balance(pool: address, user: address) -> uint256:
    return ERC20(yfi).balanceOf(pool) * ERC20(pool).balanceOf(user) / ERC20(pool).totalSupply()


@view
@internal
def sushiswap_balance(user: address) -> uint256:
    # yfi balance of slp * slp in masterchef / slp total supply
    staked: uint256 = MasterChef(masterchef).userInfo(11, user).amount + ERC20(sushiswap).balanceOf(user)
    return ERC20(yfi).balanceOf(sushiswap) * staked / ERC20(sushiswap).totalSupply()


@view
@internal
def vault_balance(user: address) -> uint256:
    total: uint256 = 0
    count: uint256 = Registry(registry).numVaults(yfi)
    for i in range(100):
        if i == count:
            break
        vault: address = Registry(registry).vaults(yfi, i)
        total += ERC20(vault).balanceOf(user) * Vault(vault).pricePerShare() / 10 ** 18
    return total


@view
@internal
def yfi_in_bancor(user: address) -> uint256:
    total: uint256 = 0
    id: uint256 = 0
    count: uint256 = Bancor(bancor).protectedLiquidityCount(user)
    liquidity: ProtectedLiquidity = empty(ProtectedLiquidity)
    for i in range(100):
        if i == count:
            break
        id = Bancor(bancor).protectedLiquidityId(user, i)
        liquidity = Bancor(bancor).protectedLiquidity(id)
        if liquidity.reserveToken == yfi:
            total += liquidity.reserveAmount
    return total


@view
@internal
def yfi_in_balancer_v2(user: address) -> uint256:
    pools: bytes32[3] = [
        0x01abc00e86c7e258823b9a055fd62ca6cf61a16300010000000000000000003b,
        0xf2b7794b89ea4fd2abfe66dcb6529a27c03d429e0002000000000000000000b0,
        0x186084ff790c65088ba694df11758fae4943ee9e000200000000000000000013,
    ]
    total: uint256 = 0
    for pool_id in pools:
        pool: address = BalancerVault(balancer_v2).getPool(pool_id)[0]
        cash: uint256 = BalancerVault(balancer_v2).getPoolTokenInfo(pool_id, yfi).cash
        total += cash * ERC20(pool).balanceOf(user) / ERC20(pool).totalSupply()
    return total


@view
@internal
def _voting_balances(user: address) -> VotingBalances:
    return VotingBalances({
        wallet: ERC20(yfi).balanceOf(user),
        vault: self.vault_balance(user),
        bancor: self.yfi_in_bancor(user),
        balancer: self.yfi_in_balancer_v2(user),
        uniswap: self.lp_balance(uniswap, user),
        sushiswap: self.sushiswap_balance(user),
        makerdao: self.makerdao_collateral(user),
        unit: Unit(unit).collaterals(yfi, user),
    })


@view
@external
def balanceOf(user: address) -> uint256:
    bal: VotingBalances = self._voting_balances(user)
    return (
        bal.wallet
        + bal.vault
        + bal.bancor
        + bal.balancer
        + bal.uniswap
        + bal.sushiswap
        + bal.makerdao
        + bal.unit
    )


@view
@external
def voting_balances(user: address) -> VotingBalances:
    return self._voting_balances(user)
