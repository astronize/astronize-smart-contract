// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract AstronizeCouponNFT is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(uint256 => bool) private _tokenIdTracker;

    string private _baseTokenURI;
    //
    constructor(
        // string memory baseTokenURI
    ) ERC721("AstronizeCouponNFT", "ACNFT") {
        // _baseTokenURI = baseTokenURI;

        //skip config
        _baseTokenURI = "https://dev-api.astronize.com/coupon/token/";

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(address to, uint256 tokenId) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "permission denied");
        require(_tokenIdTracker[tokenId] == false, "tokenId already used");
        _tokenIdTracker[tokenId] = true;

        _mint(to, tokenId);

    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        
        uint256 balance = balanceOf(owner);
        
        uint256[] memory itemList = new uint256[](balance);
        for (uint256 i=0; i < balance; i++){
            itemList[i] = tokenOfOwnerByIndex(owner, i);
        }
        return itemList;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "permission denied");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "permission denied");
        _unpause();
    }
}