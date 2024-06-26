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

topic1 = "hello-world"
topic2 = "good-day"

def initialize_groups(m_contract, owner, person):
    m_contract.createGroup(topic1, sender=owner)
    assert owner == m_contract.getGroupOwner(topic1)
    assert person != m_contract.getGroupOwner(topic1)

    # ensure GroupCreated event is emitted
    assert count_events(m_contract.GroupCreated) == 1

    m_contract.createGroup(topic2, sender=person)

def count_events(m_contract_event_topic):
    logs = m_contract_event_topic.range(0, ape.chain.blocks.head.number + 1)

    # Count number of logs
    counter = 0
    for log in logs:
        counter += 1

    return counter


def test_create_group(global_messagenger_contract, owner, not_owner):
    initialize_groups(global_messagenger_contract, owner, not_owner)

    # fails
    with pytest.raises(Exception) as e:
        global_messagenger_contract.createGroup("hello-world", sender=owner)
    assert e.value.message == "group already exists"

    # fails
    assert not_owner != global_messagenger_contract.getGroupOwner("hello-world")


def test_add_user(global_messagenger_contract, owner, not_owner):
    initialize_groups(global_messagenger_contract, owner, not_owner)

    # fails
    with pytest.raises(Exception) as e:
        global_messagenger_contract.addUserToGroup(topic1, not_owner, sender=not_owner)
    assert e.value.message == "not owner of this group"

    # fails
    with pytest.raises(Exception) as d:
        global_messagenger_contract.getGroupMessage(topic1, sender=not_owner)
    assert d.value.message == "not in group"

    global_messagenger_contract.addUserToGroup(topic1, not_owner, sender=owner)
    global_messagenger_contract.getGroupMessage(topic1, sender=not_owner)


def test_group_message(global_messagenger_contract, owner, not_owner):
    initialize_groups(global_messagenger_contract, owner, not_owner)

    global_messagenger_contract.sendGroupMessage(topic1, "message #1", sender=owner)
    val = global_messagenger_contract.getGroupMessage(topic1, sender=owner)
    assert val == "message #1"

    with pytest.raises(Exception) as e:
        global_messagenger_contract.getGroupMessage(topic1, sender=not_owner)
    assert e.value.message == "not in group"

    global_messagenger_contract.sendGroupMessage(topic1, "message #2", sender=owner)
    val = global_messagenger_contract.getGroupMessage(topic1, sender=owner)
    assert val == "message #2"

    global_messagenger_contract.sendGroupMessage(topic2, "message #3", sender=not_owner)
    val = global_messagenger_contract.getGroupMessage(topic2, sender=not_owner)
    assert val == "message #3"