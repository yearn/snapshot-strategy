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
def set_guest(guest: address, invited: bool):
    assert msg.sender == self.bouncer
    self.guests[guest] = invited

@external
def set_token(token: address, min_amount: uint256):
    assert msg.sender == self.bouncer
    self.tokens[token] = min_amount

@external
def set_active_tokens(active: address[10]):
    assert msg.sender == self.bouncer
    self.active_tokens = active

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
