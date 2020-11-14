ZERO_ADDRESS = "0x" + "0" * 40


def pad(data, fill, length):
    return data + [fill for _ in range(length - len(data))]


def test_guests(guest_list, accounts):
    bouncer, *guests = accounts
    _guests = pad(guests[:2], ZERO_ADDRESS, 20)
    _invited = pad([True], False, 20)
    guest_list.set_guests(_guests, _invited)
    assert guest_list.authorized(guests[0], 0)
    assert not guest_list.authorized(guests[1], 0)


def test_permits(guest_list, tokens, accounts):
    bouncer, *guests = accounts
    _tokens = pad(tokens, ZERO_ADDRESS, 10)
    _amounts = pad(["1 ether", "2 ether"], 0, 10)
    guest_list.set_permits(_tokens, _amounts)
    # not enough initially
    tokens[0].transfer(guests[0], "0.5 ether")
    assert not guest_list.authorized(guests[0], 0)
    # pass with another token
    tokens[1].transfer(guests[0], "3 ether")
    assert guest_list.authorized(guests[0], 0)
    # pass with exact amount
    tokens[0].transfer(guests[1], "1 ether")
    assert guest_list.authorized(guests[1], 0)
