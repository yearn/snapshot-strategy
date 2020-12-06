# Guest List

Measure productive YFI and authorize access based on decaying threshold.

Mainnet deployment: [0xcB16133a37Ef19F90C570B426292BDcca185BF47](https://etherscan.io/address/0xcb16133a37ef19f90c570b426292bdcca185bf47#code)

## Supported protocols

- YFI in wallet
- YFI staked in yGov
- YFI vault
- YFI locked in MakerDAO
- YFI/WETH Uniswap LP
- YFI/WETH Sushiswap LP
- YFI/WETH Balancer LP
- YFI/BNT Bancor Liquidty Protection

## Parameters

`min_bag` 1 YFI, starting threshold

`ape_out` 30 days, linear decay to zero 

## Interface

`invite_guest(address guest)` Invite a guest to the party.

`add_bouncer(address bouncer)` Hire an additional bouncer.

`total_yfi(address user)` Total YFI in wallet, yGov, yYFI Vault, MakerDAO, Uniswap, Sushiswap, Balancer, Bancor.

`entrance_cost(uint256 activation)` How much productive YFI is currently needed to enter.

`authorized(address guest, uint256 amount)` Check if a user with a bag of certain size is allowed to the party. Called by a Vault on `deposit`.
