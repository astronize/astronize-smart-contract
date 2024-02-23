// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IKAP721/IKAP721Receiver.sol";

contract KAP721Holder is IKAP721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onKAP721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onKAP721Received.selector;
    }
}
