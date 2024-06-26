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

// Notes
// The default value for everything in the EVM is zero

contract GlobalMessenger {

    // Contract State Variables
    struct GroupInfo {
        address owner;
        address[] members;
        string[] messages;
    }

    // Key is a unique group name
    mapping(string group => GroupInfo group_info) public groupToGroupInfoMap;

    // Events
    event GroupCreated(string indexed group_name, address indexed owner);
    event UserAdded(string indexed group_name, address indexed added);
    event NewMessage(string indexed group_name);

    constructor() {}

    modifier isOwnerOfGroup(string calldata _group) {
        require(groupToGroupInfoMap[_group].owner != address(0), "no group with that name");
        require(groupToGroupInfoMap[_group].owner == msg.sender, "not owner of this group");
        _;
    }

    modifier groupExists(string calldata _group) {
        require(groupToGroupInfoMap[_group].owner != address(0), "no group with that name");
        _;
    }

    modifier senderInGroup(string calldata _group) {
        // isInGroup checks if the group exists
        require(isInGroup(_group), "not in group");
        _;
    }

    function createGroup(string calldata _group) external {
        require(groupToGroupInfoMap[_group].owner == address(0), "group already exists");

        GroupInfo storage g = groupToGroupInfoMap[_group];
        g.owner = msg.sender;
        g.members.push(msg.sender);

        emit GroupCreated(_group, msg.sender);
    }

    function getGroupOwner(string calldata _group) external view groupExists(_group) returns (address owner) {
        return groupToGroupInfoMap[_group].owner;
    }

    function isInGroup(string calldata _group) public view groupExists(_group) returns (bool) {
        address[] memory members = groupToGroupInfoMap[_group].members;
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
        groupToGroupInfoMap[_group].messages.push(_msg);
        emit NewMessage(_group);
    }

    function getGroupMessage(string calldata _group) external view senderInGroup(_group) returns (string memory) {
        string[] memory msgs = groupToGroupInfoMap[_group].messages;
        uint l = msgs.length;

        if (l > 0){
            return msgs[l - 1];
        } else {
            return "";
        }
    }

    function addUserToGroup(string calldata _group, address _toAdd) external isOwnerOfGroup(_group) {
        groupToGroupInfoMap[_group].members.push(_toAdd);
        emit UserAdded(_group, _toAdd);
    }

}