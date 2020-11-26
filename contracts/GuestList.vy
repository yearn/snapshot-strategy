# @version 0.2.7
from vyper.interfaces import ERC20


interface Vault:
    def balanceOf(user: address) -> uint256: view
    def getPricePerFullShare() -> uint256: view


bouncer: public(address)
guests: public(HashMap[address, bool])
min_bag: public(uint256)  # 1 YFI to enter
ape_out: public(uint256)  # 30 days falloff
activation: public(uint256)
yfi: ERC20
ygov: ERC20
yyfi: Vault


@external
def __init__():
    self.bouncer = msg.sender
    self.yfi = ERC20(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e)
    self.ygov = ERC20(0xBa37B002AbaFDd8E89a1995dA52740bbC013D992)
    self.yyfi = Vault(0xBA2E7Fed597fd0E3e70f5130BcDbbFE06bB94fe1)
    self.min_bag = 10 ** 18
    self.ape_out = 86400 * 30
    self.activation = block.timestamp


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
def _total_yfi(user: address) -> uint256:
    return (
        self.yfi.balanceOf(user)
        + self.ygov.balanceOf(user)
        + self.yyfi.balanceOf(user) * self.yyfi.getPricePerFullShare() / 10 ** 18
    )


@view
@internal
def _time_factor(bag: uint256) -> uint256:
    return bag - min(bag * (block.timestamp - self.activation) / self.ape_out, bag)


@view
@external
def total_yfi(user: address) -> uint256:
    """
    Total YFI in wallet + yGov + YFI vault.
    """
    return self._total_yfi(user)


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
