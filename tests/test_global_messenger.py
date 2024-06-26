#!/usr/bin/python3

import pytest, ape
from ape import accounts, project

# With pytest, methods that are tests must start with the word "test"
# Files that you want to use must start with "test_" or end in "_test"

@pytest.fixture
def owner(accounts):
    return accounts[0]

@pytest.fixture
def global_messagenger_contract(owner, project):
    return owner.deploy(project.GlobalMessenger)

@pytest.fixture
def not_owner(accounts):
    return accounts[1]

def test_create_group(global_messagenger_contract, owner, not_owner):
    global_messagenger_contract.createGroup("hello-world", sender=owner)
    assert owner == global_messagenger_contract.getGroupOwner("hello-world")

    # ensure GroupCreated event is emitted
    event = global_messagenger_contract.GroupCreated
    logs = event.range(0, ape.chain.blocks.head.number + 1)

    # Count number of logs
    counter = 0
    for log in logs:
        counter += 1

    assert counter == 1

    # fails
    with pytest.raises(Exception) as e:
        global_messagenger_contract.createGroup("hello-world", sender=owner)
    assert e.value.message == "group already exists"

    # fails
    assert not_owner != global_messagenger_contract.getGroupOwner("hello-world")

def test_add_user(global_messagenger_contract, owner, not_owner):
    global_messagenger_contract.createGroup("hello-world", sender=owner)
    assert owner == global_messagenger_contract.getGroupOwner("hello-world")

    # fails
    with pytest.raises(Exception) as e:
        global_messagenger_contract.addUserToGroup("hello-world", not_owner, sender=not_owner)
    assert e.value.message == "not owner of this group"

    # fails
    with pytest.raises(Exception) as d:
        global_messagenger_contract.getGroupMessage("hello-world", sender=not_owner)
    assert d.value.message == "not in group"

    global_messagenger_contract.addUserToGroup("hello-world", not_owner, sender=owner)
    global_messagenger_contract.getGroupMessage("hello-world", sender=not_owner)

def test_group_message(global_messagenger_contract, owner, not_owner):
    global_messagenger_contract.createGroup("hello-world", sender=owner)
    assert owner == global_messagenger_contract.getGroupOwner("hello-world")

    global_messagenger_contract.sendGroupMessage("hello-world", "message #1", sender=owner)
    val = global_messagenger_contract.getGroupMessage("hello-world", sender=owner)
    assert val == "message #1"

    with pytest.raises(Exception) as e:
        global_messagenger_contract.getGroupMessage("hello-world", sender=not_owner)
    assert e.value.message == "not in group"