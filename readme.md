# Yearn Voting

Calculate voting power from productive YFI to be used on Snapshot.

Mainnet deployment: [`--`](https://etherscan.io/address/--)

## Measures YFI

- Wallet
- Yearn v2 YFI Vault
- Bancor
- Balancer v2 YFI/WETH
- Uniswap v2
- Sushiswap YFI/WETH incl. MasterChef
- MakerDAO collateral
- Unit collateral
- Instadapp DeFi Smart Account, incl. MakerDAO

## Interface

- `balanceOf(address user) -> uint256`

- `voting_balances(address user) -> VotingBalances`
