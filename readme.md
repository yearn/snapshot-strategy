# Guest List

Measure productive YFI and authorize access based on decaying threshold.

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

`set_guest(address,bool)` Invite or kick guests from the party.

`set_bouncer(address)` Replace bouncer role.

`bribe_the_bouncer()` Sneak into the party by bribing the bouncer with 2% of the entrance cost.

`total_yfi(address)` Total YFI in wallet, yGov, Vault, MakerDAO, Uniswap, Sushiswap, Balancer, Bancor.

`entrance_cost()` How much productive YFI is currently needed to enter.

`bribe_cost()` How much YFI to bribe the bouncer to enter.

`authorized(address,uint256)` Check if a user with a bag of certain size is allowed to the party.
