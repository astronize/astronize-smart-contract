// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IKAP721TransferRouter {
    event InternalTransfer(address indexed tokenAddress, address indexed sender, address indexed recipient, uint256 id);

    event ExternalTransfer(address indexed tokenAddress, address indexed sender, address indexed recipient, uint256 id);

    function isAllowedAddr(address _addr) external view returns (bool);

    function allowedAddrLength() external view returns (uint256);

    function allowedAddrByIndex(uint256 _index) external view returns (address);

    function allowedAddrByPage(uint256 _page, uint256 _limit) external view returns (address[] memory);

    function addAddress(address _addr) external;

    function revokeAddress(address _addr) external;

    function internalTransfer(
        address tokenAddress,
        address sender,
        address recipient,
        uint256 id
    ) external returns (bool);

    function externalTransfer(
        address tokenAddress,
        address sender,
        address recipient,
        uint256 id
    ) external returns (bool);
}
