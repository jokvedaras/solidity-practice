// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * Requirements
 * - Users send messages to a group (unique group name)
 * - Only users in group can send and view messages (map group to users)
 * - Groups are created by a method call - default to adding the caller as the only user in group
 * - Groups are deleted by a method call
 * - Groups can add/remove users by a method call
 * - Users can view the history of the messages or just the latest (maybe latest X)
 * - emit events when groups are created, users are added/removed, messages are added
 */

contract GlobalMessenger {

    // Contract State Variables

    // TODO - Refactor to a struct that contains the address and isOwner/isAdmin boolean
    // TODO - May even add history of messages in the struct? unsure
    // Unique group name to all members
    mapping(string group => address[] members) public groupToMemberMap;

    // Unique group name to owner
    mapping(string group => address owner) public groupToOwnerMap;

    // Unique group name to list of messages
    mapping(string group => string[] msgs) public groupToMessagesMap;

    // Events
    event GroupCreated(string indexed group_name, address indexed owner);
    event UserAdded(string indexed group_name, address indexed added);
    event NewMessage(string indexed group_name);

    constructor() {}

    modifier isOwnerOfGroup(string calldata _group) {
        require(groupToOwnerMap[_group] != address(0), "no group with that name");
        require(groupToOwnerMap[_group] == msg.sender, "not owner of this group");
        _;
    }

    modifier groupExists(string calldata _group) {
        require(groupToOwnerMap[_group] != address(0), "no group with that name");
        _;
    }

    modifier senderInGroup(string calldata _group) {
        // isInGroup checks if the group exists
        require(isInGroup(_group), "not in group");
        _;
    }

    function createGroup(string calldata _group) external {
        require(groupToOwnerMap[_group] == address(0), "group already exists");

        groupToMemberMap[_group].push(msg.sender);
        groupToOwnerMap[_group]  = msg.sender;

        emit GroupCreated(_group, msg.sender);
    }

    function getGroupOwner(string calldata _group) external view groupExists(_group) returns (address owner) {
        return groupToOwnerMap[_group];
    }

    function isInGroup(string calldata _group) public view groupExists(_group) returns (bool) {
        address[] memory members = groupToMemberMap[_group];
        for (uint i = 0; i < members.length; i++)
        {
            if (members[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function sendGroupMessage(string calldata _group, string calldata _msg) external senderInGroup(_group) {
        // Add message to structure.
        groupToMessagesMap[_group].push(_msg);
        emit NewMessage(_group);
    }

    function getGroupMessage(string calldata _group) external view senderInGroup(_group) returns (string memory) {
        string[] memory msgs = groupToMessagesMap[_group];
        uint l = msgs.length;

        if (l > 0){
            return msgs[l - 1];
        } else {
            return "";
        }
    }

    function addUserToGroup(string calldata _group, address _toAdd) external isOwnerOfGroup(_group) {
        groupToMemberMap[_group].push(_toAdd);
        emit UserAdded(_group, _toAdd);
    }

}