// SPDX-License-Identifier: MIT



pragma solidity >=0.6.0;

interface IOwnerAccessControlRouter {
    function isOwner(string memory ownerRoleName, address owner) external view returns (bool);

    function isRootOwner(address rootOwner) external view returns (bool);
}
