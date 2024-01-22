// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.8.3 https://hardhat.org

pragma solidity >=0.6.0 <0.9.0;

interface IOwnerAccessControl {
    function isOwner(string memory ownerRoleName, address owner) external view returns (bool);

    function isRootOwner(address _rootOwner) external view returns (bool);
}

