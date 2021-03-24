# Yearn Voting

Calculate voting power from productive YFI to be used on Snapshot.

Mainnet deployment: [`0x5584e034094BBC734751fE48A701e9758e1dDA88`](https://etherscan.io/address/0x5584e034094BBC734751fE48A701e9758e1dDA88)

## Measures YFI

- Wallet
- yvYFI v2 Vault
- Bancor
- Balancer YFI/WETH
- Uniswap
- Sushiswap YFI/WETH
- SLP staked in MasterChef
- MakerDAO collateral
- Unit collateral

## Interface

- `balanceOf(address user) -> uint256`

- `voting_balances(address user) -> VotingBalances`
