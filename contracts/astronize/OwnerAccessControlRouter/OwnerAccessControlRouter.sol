// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/interfaces/IOwnerAccessControl.sol


pragma solidity >=0.6.0 <0.9.0;

interface IOwnerAccessControl {
    function isOwner(string memory ownerRoleName, address owner) external view returns (bool);

    function isRootOwner(address _rootOwner) external view returns (bool);
}


// File contracts/OwnerAccessControlRouter.sol


pragma solidity 0.8.19;

contract OwnerAccessControlRouter {
    IOwnerAccessControl public ownerAccessControl;

    constructor(address _ownerAccessControl) public {
        ownerAccessControl = IOwnerAccessControl(_ownerAccessControl);
    }

    function setOwnerAccessControl(address _ownerAccessControl) external {
        require(isRootOwner(msg.sender), "OwnerAccessControlRouter: caller is not root owner");
        ownerAccessControl = IOwnerAccessControl(_ownerAccessControl);
    }

    function isRootOwner(address rootOwner) public view returns (bool) {
        return ownerAccessControl.isRootOwner(rootOwner);
    }

    function isOwner(string memory ownerRoleName, address owner) external view returns (bool) {
        return ownerAccessControl.isOwner(ownerRoleName, owner);
    }
}