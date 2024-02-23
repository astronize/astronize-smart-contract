// SPDX-License-Identifier: MIT


pragma solidity 0.8.19;

import "./kap20/token/KAP20.sol";
import "./kap20/interfaces/IOwnerAccessControlRouter.sol";




// KAP-20, KAP-721 Standard: V.1.0.0
// This KAP proposes an interface standard to create token contracts on Bitkub Chain.
// This Smart Contract does not provide the basic functionality, it only provides the required standard functions that define the implementation of APIs for KAP standard.
// This Smart Contract contains a set of operations that control how to communicate on the ecosystem of Bitkub applications on Bitkub Chain.


contract ASTTokenKAP20 is KAP20 {

    IOwnerAccessControlRouter public ownerAccessControlRouter;

    //role init
    string private constant _MINTER_NAME = "MINTER";
    string private constant _BURNER_NAME = "BURNER";

    string public constant _PAUSER_ROLE = "PAUSER_ROLE";

    event OwnerAccessControlRouterSet(address indexed operator, address indexed oldAddress, address indexed newAddress);

    modifier onlyPause() {
        require(
           (address(ownerAccessControlRouter) != address(0) &&
                    ownerAccessControlRouter.isOwner(_PAUSER_ROLE, msg.sender)),
            "Restricted only pause role"
        );
        _;
    }

    modifier onlyMinter() {
        require(
           (address(ownerAccessControlRouter) != address(0) &&
                    ownerAccessControlRouter.isOwner(_MINTER_NAME, msg.sender)),
            "Restricted only minter"
        );
        _;
    }

    modifier onlyBurner() {
        require(
           (address(ownerAccessControlRouter) != address(0) &&
                    ownerAccessControlRouter.isOwner(_BURNER_NAME, msg.sender)),
            "Restricted only burner"
        );
        _;
    }

    modifier onlySuperAdminOrOwnerOrHolder(address _burner) {
        require(
            adminProjectRouter.isSuperAdmin(msg.sender, PROJECT) || msg.sender == owner() || msg.sender == _burner,
            "BitkubKAP20: restricted only super admin or owner or holder"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _projectName,
        uint8 _decimals,
        address _kyc,
        address _adminProjectRouter,
        address _committee,
        address _transferRouter,
        uint256 _acceptedKYCLevel,
        address _ownerAccessControlRouter
    )
        KAP20(
            _name,
            _symbol,
            _projectName,
            _decimals,
            _kyc,
            _adminProjectRouter,
            _committee,
            _transferRouter,
            _acceptedKYCLevel
        )
    {
        ownerAccessControlRouter = IOwnerAccessControlRouter(_ownerAccessControlRouter);
        
    }

    function setOwnerAccessControlRouter(address _ownerAccessControlRouter) external onlyOwner {
        emit OwnerAccessControlRouterSet(msg.sender, address(ownerAccessControlRouter), _ownerAccessControlRouter);
        ownerAccessControlRouter = IOwnerAccessControlRouter(_ownerAccessControlRouter);
    }

    function pause() external onlyPause {
        _pause();
    }

    function unpause() external onlyPause {
        _unpause();
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function mint(address _to, uint256 _amount) external onlyMinter whenNotPaused {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyBurner whenNotPaused {
        _burn(_from, _amount);
    }
}

// KAP-20, KAP-721 Standard: V.1.0.0
// This KAP proposes an interface standard to create token contracts on Bitkub Chain.
// This Smart Contract does not provide the basic functionality, it only provides the required standard functions that define the implementation of APIs for KAP standard.
// This Smart Contract contains a set of operations that control how to communicate on the ecosystem of Bitkub applications on Bitkub Chain.