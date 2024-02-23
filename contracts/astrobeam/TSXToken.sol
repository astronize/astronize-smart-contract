// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./shared/token/KAP20.sol";
import "./shared/interfaces/IOwnerAccessControlRouter.sol";

contract TSXToken is KAP20 {
    event OwnerAccessControlRouterSet(address indexed operator, address indexed oldAddress, address indexed newAddress);

    string private constant _OWNER_NAME = "OWNER";
    string private constant _MINTER_NAME = "MINTER";
    string private constant _BURNER_NAME = "BURNER";
    string private constant _PAUSER_NAME = "PAUSER";

    modifier onlyRoot() {
        require(address(ownerAccessControlRouter) != address(0) && ownerAccessControlRouter.isRootOwner(msg.sender),
            "Restricted only root"
        );
        _;
    }

    modifier onlyOwner() {
        require(address(ownerAccessControlRouter) != address(0) &&
                    ownerAccessControlRouter.isOwner(_OWNER_NAME, msg.sender),
            "Restricted only owner"
        );
        _;
    }

    modifier onlyMinter() {
        require(address(ownerAccessControlRouter) != address(0) &&
                    ownerAccessControlRouter.isOwner(_MINTER_NAME, msg.sender),
            "Restricted only minter"
        );
        _;
    }

    modifier onlyBurner() {
        require(address(ownerAccessControlRouter) != address(0) &&
                    ownerAccessControlRouter.isOwner(_BURNER_NAME, msg.sender),
            "Restricted only burner"
        );
        _;
    }

    modifier onlyPauser() {
        require(address(ownerAccessControlRouter) != address(0) &&
                    ownerAccessControlRouter.isOwner(_PAUSER_NAME, msg.sender),
            "Restricted only pauser"
        );
        _;
    }

    IOwnerAccessControlRouter public ownerAccessControlRouter;

    constructor(
        address _adminProjectRouter,
        address _kyc,
        address _committee,
        uint256 _acceptedKycLevel,
        address _transferRouter,
        address _ownerAccessControlRouter
    )
        KAP20(
            "TSX Token",
            "TSX",
            "astronize",
            18,
            _kyc,
            _adminProjectRouter,
            _committee,
            _transferRouter,
            _acceptedKycLevel
        )
    {
        ownerAccessControlRouter = IOwnerAccessControlRouter(_ownerAccessControlRouter);
    }

    function setOwnerAccessControlRouter(address _ownerAccessControlRouter) external onlyRoot {
        emit OwnerAccessControlRouterSet(msg.sender, address(ownerAccessControlRouter), _ownerAccessControlRouter);
        ownerAccessControlRouter = IOwnerAccessControlRouter(_ownerAccessControlRouter);
    }

    ////////////////////////////////////////////////////////////////////////////////

    function pause() external onlyPauser {
        _pause();
    }

    function unpause() external onlyPauser {
        _unpause();
    }

    ////////////////////////////////////////////////////////////////////////////////

    function mint(address _to, uint256 _amount) external whenNotPaused onlyMinter returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    function burn(uint256 _amount) external whenNotPaused onlyBurner returns (bool) {
        _burn(msg.sender, _amount);
        return true;
    }

    function burnFrom(address _account, uint256 _amount) external whenNotPaused onlyBurner {
        uint256 currentAllowance = allowance(_account, msg.sender);
        require(currentAllowance >= _amount, "KAP20: burn amount exceeds allowance");
        unchecked {
            _approve(_account, msg.sender, currentAllowance - _amount);
        }
        _burn(_account, _amount);
    }

}
