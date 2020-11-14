import pytest


@pytest.fixture(scope="function", autouse=True)
def shared_setup(fn_isolation):
    pass


@pytest.fixture()
def tokens(ERC20, accounts):
    names = ["Token A", "Token B"]
    symbols = ["TOA", "TOB"]
    decimals = 18
    supply = 10_000
    return [
        ERC20.deploy(name, symbol, decimals, supply, {"from": accounts[0]})
        for name, symbol in zip(names, symbols)
    ]


@pytest.fixture()
def guest_list(GuestList, accounts):
    return GuestList.deploy({"from": accounts[0]})
