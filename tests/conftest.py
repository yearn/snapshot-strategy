import pytest


@pytest.fixture(scope="function", autouse=True)
def shared_setup(fn_isolation):
    pass


@pytest.fixture
def bouncer(accounts):
    return accounts[0]


@pytest.fixture
def whale(accounts):
    return accounts.at("0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE", force=True)


@pytest.fixture
def yfi(interface, whale):
    return interface.ERC20("0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e", owner=whale)


@pytest.fixture
def ygov(interface, guest):
    return interface.yGov("0xBa37B002AbaFDd8E89a1995dA52740bbC013D992", owner=guest)


@pytest.fixture
def yyfi(interface, guest):
    return interface.yVault("0xBA2E7Fed597fd0E3e70f5130BcDbbFE06bB94fe1", owner=guest)


@pytest.fixture
def guest_list(GuestList, bouncer):
    return GuestList.deploy({"from": bouncer})


@pytest.fixture
def vault(TestVault, guest_list, bouncer):
    return TestVault.deploy(guest_list, {"from": bouncer})


@pytest.fixture
def guest(accounts):
    return accounts[1]
