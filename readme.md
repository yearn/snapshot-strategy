# Guest List

Measure productive YFI and authorize access based on decaying threshold.

Mainnet deployment: [0x5d38391c9DA9Ce9daC1a7b3899e9F40E4d01F68C](https://etherscan.io/address/0x5d38391c9da9ce9dac1a7b3899e9f40e4d01f68c#code)

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
