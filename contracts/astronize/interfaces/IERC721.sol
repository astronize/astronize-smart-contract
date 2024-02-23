// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC721 {

    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}