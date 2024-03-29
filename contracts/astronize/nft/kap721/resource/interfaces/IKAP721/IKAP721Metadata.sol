// SPDX-License-Identifier: MIT


pragma solidity >=0.6.0 <0.9.0;

interface IKAP721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}