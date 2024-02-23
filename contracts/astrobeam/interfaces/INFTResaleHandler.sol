// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface INFTResaleHandler {
    function setSold(address _tokenAddress, uint256 _tokenId) external;
    function canSell(address _tokenAddress, uint256 _tokenId) external view returns (bool);
}