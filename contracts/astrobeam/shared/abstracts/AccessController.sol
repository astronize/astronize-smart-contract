// SPDX-License-Identifier: MIT

import "./standard/Authorization.sol";
import "./standard/KYCHandler.sol";
import "./Committee.sol";
import "./Ownable.sol";

pragma solidity ^0.8.0;

abstract contract AccessController is Authorization, KYCHandler, Committee {
    address public transferRouter;

    event TransferRouterSet(
        address indexed oldTransferRouter,
        address indexed newTransferRouter,
        address indexed caller
    );

    modifier onlySuperAdminOrTransferRouter() {
        require(
            adminProjectRouter.isSuperAdmin(msg.sender, PROJECT) || msg.sender == transferRouter,
            "AccessController: restricted only super admin or transfer router"
        );
        _;
    }

    modifier onlySuperAdminOrCommittee() {
        require(
            adminProjectRouter.isSuperAdmin(msg.sender, PROJECT) || msg.sender == committee,
            "AccessController: restricted only super admin or committee"
        );
        _;
    }

    function activateOnlyKYCAddress() external onlyCommittee {
        _activateOnlyKYCAddress();
    }

    function setKYC(address _kyc) external onlyCommittee {
        _setKYC(_kyc);
    }

    function setAcceptedKYCLevel(uint256 _kycLevel) external onlyCommittee {
        _setAcceptedKYCLevel(_kycLevel);
    }

    function setTransferRouter(address _transferRouter) external onlyCommittee {
        emit TransferRouterSet(transferRouter, _transferRouter, msg.sender);
        transferRouter = _transferRouter;
    }

    function setAdminProjectRouter(address _adminProjectRouter) public override onlyCommittee {
        require(_adminProjectRouter != address(0), "Authorization: new admin project router is the zero address");
        emit AdminProjectRouterSet(address(adminProjectRouter), _adminProjectRouter, msg.sender);
        adminProjectRouter = IAdminProjectRouter(_adminProjectRouter);
    }
}
