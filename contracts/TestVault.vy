# @version 0.2.7

interface GuestList:
    def authorized(guest: address, amount: uint256) -> bool: view


activation: public(uint256)
guest_list: public(GuestList)


@external
def __init__(_guest_list: address):
    self.activation = block.timestamp
    self.guest_list = GuestList(_guest_list)


@view
@external
def authorized(guest: address, amount: uint256) -> bool:
    return self.guest_list.authorized(guest, amount)
