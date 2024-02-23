// SPDX-License-Identifier: MIT

// File contracts/shared/interfaces/IKAP165.sol


pragma solidity ^0.8.0;

interface IKAP165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
