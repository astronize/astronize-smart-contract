// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Blacklist {
    mapping(address => bool) public blacklist;

    event AddBlacklist(address indexed account, address indexed caller);

    event RevokeBlacklist(address indexed account, address indexed caller);

    modifier notInBlacklist(address account) {
        require(!blacklist[account], "Address is in blacklist");
        _;
    }

    modifier inBlacklist(address account) {
        require(blacklist[account], "Address is not in blacklist");
        _;
    }

    function _addBlacklist(address account) internal virtual notInBlacklist(account) {
        blacklist[account] = true;
        emit AddBlacklist(account, msg.sender);
    }

    function _revokeBlacklist(address account) internal virtual inBlacklist(account) {
        blacklist[account] = false;
        emit RevokeBlacklist(account, msg.sender);
    }
}
