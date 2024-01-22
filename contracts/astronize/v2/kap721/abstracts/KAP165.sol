// SPDX-License-Identifier: MIT


import "../interfaces/IKAP165.sol";

pragma solidity ^0.8.0;

abstract contract KAP165 is IKAP165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IKAP165).interfaceId;
    }
}