// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract NFTResaleHandler is AccessControlEnumerable{

     constructor()
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MKP_ROLE, msg.sender);
        setAcivate(true);
    }

    // role init
    bytes32 public constant MKP_ROLE = keccak256("MKP_ROLE");

    bool private isAcivate;
    mapping(address => mapping(uint256 => bool)) private isSold;

    // event
    event SoldChange(address indexed sender, address _tokenAddress, uint256 tokenId);
    event AcivateChange(address indexed sender, bool _isAcivate);

    function canSell(address _tokenAddress, uint256 _tokenId) external view returns (bool) {
        if (isAcivate) {
            return !isSold[_tokenAddress][_tokenId];
        } else {
            return true;
        }
    }

    function setSold(address _tokenAddress, uint256 _tokenId) external onlyRole(MKP_ROLE) {
        if (isAcivate) {
            isSold[_tokenAddress][_tokenId] = true;
            emit SoldChange(msg.sender, _tokenAddress, _tokenId);
        }
    }

    function setAcivate(bool _isAcivate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        isAcivate = _isAcivate;
        emit AcivateChange(msg.sender, _isAcivate);
    }
}



