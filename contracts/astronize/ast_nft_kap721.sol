// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import "./nft/kap721/resource/token/KAP721.sol";
import "./nft/kap721/resource/interfaces/IOwnerAccessControlRouter.sol";

contract AstronizeNFTKAP721 is KAP721 {

    event OwnerAccessControlRouterSet(address indexed operator, address indexed oldAddress, address indexed newAddress);
    event TokenURISet(address indexed sender, uint256 indexed tokenId, string indexed tokenURI);
    event BaseURISet(address indexed sender, string indexed baseURI);
  
    string private constant _OWNER_NAME = "OWNER";
    string private constant _MINTER_NAME = "MINTER";
    string private constant _BURNER_NAME = "BURNER";

    string public constant _PAUSER_ROLE = "PAUSER_ROLE";

    modifier onlyPause() {
        require(
           (address(ownerAccessControlRouter) != address(0) &&
                    ownerAccessControlRouter.isOwner(_PAUSER_ROLE, msg.sender)),
            "Restricted only pause role"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            (address(ownerAccessControlRouter) != address(0) &&
                    ownerAccessControlRouter.isOwner(_OWNER_NAME, msg.sender)),
            "Restricted only owner"
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

    IOwnerAccessControlRouter public ownerAccessControlRouter;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _projectName,
        address _kyc,
        address _adminProjectRouter,
        address _committee,
        address _transferRouter,
        uint256 _acceptedKycLevel,
        address _ownerAccessControlRouter
    )
        KAP721(
            _name,
            _symbol,
            _baseURI,
            _projectName,
            _kyc,
            _adminProjectRouter,
            _committee,
            _transferRouter,
            _acceptedKycLevel
        )
    {
        ownerAccessControlRouter = IOwnerAccessControlRouter(_ownerAccessControlRouter);
    }

    function setOwnerAccessControlRouter(address _ownerAccessControlRouter) external onlyOwner {
        emit OwnerAccessControlRouterSet(msg.sender, address(ownerAccessControlRouter), _ownerAccessControlRouter);
        ownerAccessControlRouter = IOwnerAccessControlRouter(_ownerAccessControlRouter);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external onlyOwner {
        emit TokenURISet(msg.sender, _tokenId, _tokenURI);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        emit BaseURISet(msg.sender, _baseURI);
        _setBaseURI(_baseURI);
    }

    function pause() external onlyPause {
        _pause();
    }

    function unpause() external onlyPause {
        _unpause();
    }

    function burn(uint256 _tokenId) external whenNotPaused onlyBurner {
        _burn(_tokenId);
    }

    mapping(uint256 => bool) private _tokenIdTracker;

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        
        uint256 balance = balanceOf(owner);
        
        uint256[] memory itemList = new uint256[](balance);
        for (uint256 i=0; i < balance; i++){
            itemList[i] = tokenOfOwnerByIndex(owner, i);
        }
        return itemList;
    }

    function mint(address to, uint256 tokenId) external whenNotPaused onlyMinter {

        require(_tokenIdTracker[tokenId] == false, "tokenId already used");
        _tokenIdTracker[tokenId] = true;

        _mint(to, tokenId);

    }

}

