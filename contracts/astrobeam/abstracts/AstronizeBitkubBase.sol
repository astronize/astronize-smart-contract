// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "../shared/interfaces/IOwnerAccessControlRouter.sol";
import "./BitkubChain.sol";
import "../shared/interfaces/INextTransferRouter.sol";
import "../shared/interfaces/IKAP20/IAstrobeamKAP20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract AstronizeBitkubBase is Pausable, BitkubChain {
    using SafeERC20 for IERC20;
    event NextTransferRouterSet(address indexed caller, address indexed oldAddress, address indexed newAddress);
    event CallHelperSet(address from,address to);
    event OwnerAccessControlRouterSet(
        address indexed operator,
        address indexed oldAddress,
        address indexed newAddress
    );

    INextTransferRouter public nextTransferRouter;
    address public callHelper;
    IOwnerAccessControlRouter public ownerAccessControlRouter;

    string private constant _OWNER_NAME = "OWNER";
    string private constant _OPERATOR_NAME = "OPERATOR";
    string private constant _MODERATOR_NAME = "MODERATOR";
    string private constant _PAUSER_NAME = "PAUSER";

    modifier onlyOwner() {
        require(
            (address(ownerAccessControlRouter) != address(0) &&
                ownerAccessControlRouter.isOwner(_OWNER_NAME, msg.sender)),
            "Restricted only owner"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            (address(ownerAccessControlRouter) != address(0) &&
                ownerAccessControlRouter.isOwner(_OPERATOR_NAME, msg.sender)),
            "Restricted only operator"
        );
        _;
    }

    modifier onlyModerator() {
        require(
            (address(ownerAccessControlRouter) != address(0) &&
                ownerAccessControlRouter.isOwner(_MODERATOR_NAME, msg.sender)),
            "Restricted only moderator"
        );
        _;
    }

    modifier onlyPauser() {
        require(
            (address(ownerAccessControlRouter) != address(0) &&
                ownerAccessControlRouter.isOwner(_PAUSER_NAME, msg.sender)),
            "Restricted only pauser"
        );
        _;
    }

    modifier onlyRoot() {
        require(
            (address(ownerAccessControlRouter) != address(0) &&
                ownerAccessControlRouter.isRootOwner(msg.sender)),
            "Restricted only root"
        );
        _;
    }

    modifier onlyCallHelper() {
        require(msg.sender == callHelper, "onlyCallHelper: restricted only call helper");
        _;
    }

    modifier onlyBitkubNextUser(address bitkubNextAddress) {
        require(kyc.kycsLevel(bitkubNextAddress) >= acceptedKycLevel, "onlyBitkubNextUser: restricted only Bitkub NEXT user");
        _;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // admin
    function setCallHelper(address _callHelper) external onlyRoot {
        emit CallHelperSet(callHelper,_callHelper);
        callHelper = _callHelper;
    }

    function setOwnerAccessControlRouter(address _ownerAccessControlRouter)
        external
        onlyRoot
    {
        emit OwnerAccessControlRouterSet(
            msg.sender,
            address(ownerAccessControlRouter),
            _ownerAccessControlRouter
        );
        ownerAccessControlRouter = IOwnerAccessControlRouter(
            _ownerAccessControlRouter
        );
    }

    function pause() external onlyPauser {
        _pause();
    }

    function unpause() external onlyPauser {
        _unpause();
    }

    function setNextTransferRouter(address _nextTransferRouter) external onlyOwner {
        emit NextTransferRouterSet(msg.sender, address(nextTransferRouter), _nextTransferRouter);
        nextTransferRouter = INextTransferRouter(_nextTransferRouter);
    }

    /**
     * @notice transfer token 
     * @param from: from address
     * @param to: to address
     * @param token: kap20 currency address
     * @param amount: amount to transfer
     */
    function _transferToken(
        address from,
        address to,
        address token,
        uint256 amount
    ) internal {
        if (kyc.kycsLevel(from) >= acceptedKycLevel) {
            // bitkubnext
            nextTransferRouter.transferFrom(PROJECT, token, from, to, amount);
        } else {
            // meta mask
            IERC20(token).safeTransferFrom(from, to, amount);
        }
    }
}
