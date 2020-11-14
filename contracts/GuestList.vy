# @version 0.2.7
from vyper.interfaces import ERC20

bouncer: public(address)
guests: public(HashMap[address, bool])
tokens: public(HashMap[address, uint256])
active_tokens: public(address[10])


@external
def __init__():
    self.bouncer = msg.sender


@external
def set_guests(guest: address[20], invited: bool[20]):
    assert msg.sender == self.bouncer
    for i in range(20):
        if guest[i] == ZERO_ADDRESS:
            break
        self.guests[guest[i]] = invited[i]

@external
def set_tokens(token: address[10], min_amount: uint256[10]):
    assert msg.sender == self.bouncer
    self.active_tokens = token
    for i in range(10):
        if token[i] == ZERO_ADDRESS:
            break
        self.tokens[token[i]] = min_amount[i]


@external
def set_bouncer(new_bouncer: address):
    assert msg.sender == self.bouncer
    self.bouncer = new_bouncer


@view
@external
def authorized(guest: address, amount: uint256) -> bool:
    if self.guests[guest]:
        return True
    for token in self.active_tokens:
        if token == ZERO_ADDRESS:
            break
        if ERC20(token).balanceOf(guest) >= self.tokens[token]:
            return True
    return False
