// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IKAP721 {

    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external;
}