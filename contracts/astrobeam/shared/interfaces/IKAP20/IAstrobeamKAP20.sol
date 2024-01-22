// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IKAP20.sol";

interface IAstrobeamKAP20 is IKAP20 {
    function mint(address _to, uint256 _amount) external returns (bool);

    function burn(uint256 _amount) external returns (bool);

    function burnFrom(address _account, uint256 _amount) external;
}
