def test_override(guest_list, guest):
    assert not guest_list.authorized(guest, 0)
    guest_list.set_guest(guest, True)
    assert guest_list.authorized(guest, 0)
    guest_list.set_guest(guest, False)
    assert not guest_list.authorized(guest, 0)


def test_yfi(guest_list, guest, yfi):
    assert not guest_list.authorized(guest, 0)
    bag = guest_list.min_bag()
    yfi.transfer(guest, bag)
    assert guest_list.total_yfi(guest) == bag
    assert guest_list.authorized(guest, 0)


def test_ygov(guest_list, guest, yfi, ygov):
    assert not guest_list.authorized(guest, 0)
    bag = guest_list.min_bag()
    yfi.transfer(guest, bag)
    yfi.approve(ygov, bag, {"from": guest})
    ygov.stake(bag)
    assert guest_list.total_yfi(guest) == bag
    assert guest_list.authorized(guest, 0)


def test_yyfi(guest_list, guest, yfi, yyfi):
    assert not guest_list.authorized(guest, 0)
    bag = guest_list.min_bag() + 1
    yfi.transfer(guest, bag)
    yfi.approve(yyfi, bag, {"from": guest})
    yyfi.deposit(bag)
    assert guest_list.total_yfi(guest) >= guest_list.min_bag()
    assert guest_list.authorized(guest, 0)


def test_combined(guest_list, guest, yfi, ygov, yyfi):
    assert not guest_list.authorized(guest, 0)
    bag = guest_list.min_bag() + 1
    yfi.transfer(guest, bag)
    yfi.approve(ygov, bag, {"from": guest})
    ygov.stake(bag / 3)
    yfi.approve(yyfi, bag, {"from": guest})
    yyfi.deposit(yfi.balanceOf(guest))
    assert guest_list.total_yfi(guest) >= guest_list.min_bag()
    assert guest_list.authorized(guest, 0)
