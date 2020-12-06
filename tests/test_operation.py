def test_override(guest_list, vault, guest):
    assert not vault.authorized(guest, 0)
    tx = guest_list.invite_guest(guest)
    assert 'GuestInvited' in tx.events
    assert vault.authorized(guest, 0)


def test_yfi(guest_list, vault, guest, yfi):
    assert not vault.authorized(guest, 0)
    bag = guest_list.min_bag()
    yfi.transfer(guest, bag)
    assert guest_list.total_yfi(guest) == bag
    assert vault.authorized(guest, 0)


def test_ygov(guest_list, vault, guest, yfi, ygov):
    assert not vault.authorized(guest, 0)
    bag = guest_list.min_bag()
    yfi.transfer(guest, bag)
    yfi.approve(ygov, bag, {"from": guest})
    ygov.stake(bag)
    assert guest_list.total_yfi(guest) == bag
    assert vault.authorized(guest, 0)


def test_yyfi(guest_list, vault, guest, yfi, yyfi):
    assert not vault.authorized(guest, 0)
    bag = guest_list.min_bag() + 100
    yfi.transfer(guest, bag)
    yfi.approve(yyfi, bag, {"from": guest})
    yyfi.deposit(bag)
    assert guest_list.total_yfi(guest) >= guest_list.min_bag()
    assert vault.authorized(guest, 0)


def test_combined(guest_list, vault, guest, yfi, ygov, yyfi):
    assert not vault.authorized(guest, 0)
    bag = guest_list.min_bag() + 100
    yfi.transfer(guest, bag)
    yfi.approve(ygov, bag, {"from": guest})
    ygov.stake(bag / 3)
    yfi.approve(yyfi, bag, {"from": guest})
    yyfi.deposit(yfi.balanceOf(guest))
    assert guest_list.total_yfi(guest) >= guest_list.min_bag()
    assert vault.authorized(guest, 0)


def test_decay(guest_list, vault, chain):
    start = vault.activation()
    assert guest_list.entrance_cost(start) == guest_list.min_bag()
    for i in range(9, -1, -1):
        chain.sleep(guest_list.ape_out() // 10)
        chain.mine()
        assert guest_list.entrance_cost(start) <= guest_list.min_bag() * i / 10
        print(guest_list.entrance_cost(start))


def test_bribe(guest_list, vault, guest, yfi):
    assert not vault.authorized(guest, 0)
    bribe = guest_list.bribe_cost()
    yfi.transfer(guest, bribe)
    yfi.approve(guest_list, bribe, {"from": guest})
    tx = guest_list.bribe_the_bouncer({"from": guest})
    assert 'GuestInvited' in tx.events
    assert 'BribeReceived' in tx.events
    assert vault.authorized(guest, 0)
