// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Authorization {
    address public committee;
    address public admin;

    event SetAdmin(address indexed oldAdmin, address indexed newAdmin, address indexed caller);
    event SetCommittee(address indexed oldCommittee, address indexed newCommittee, address indexed caller);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Restricted only admin");
        _;
    }

    modifier onlyCommittee() {
        require(msg.sender == committee, "Restricted only committee");
        _;
    }

    modifier onlyAdminOrCommittee() {
        require(msg.sender == committee || msg.sender == admin, "Restricted only committee or admin");
        _;
    }

    function setAdmin(address _admin) external onlyCommittee {
        emit SetAdmin(admin, _admin, msg.sender);
        admin = _admin;
    }

    function setCommittee(address _committee) external onlyCommittee {
        emit SetCommittee(committee, _committee, msg.sender);
        committee = _committee;
    }
}