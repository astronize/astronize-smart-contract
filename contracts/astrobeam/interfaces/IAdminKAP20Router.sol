// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IAdminKAP20Router {

    function isAllowedAddr(address _addr) external view returns (bool);

    function allowedAddrLength() external view returns (uint256);

    function allowedAddrByIndex(uint256 _index) external view returns (address);

    function allowedAddrByPage(uint256 _page, uint256 _limit) external view returns (address[] memory);

    function addAddress(address _addr) external;

    function revokeAddress(address _addr) external;

    function internalTransfer(
        address _token,
        address _feeToken,
        address _from,
        address _to,
        uint256 _value,
        uint256 _feeValue
    ) external returns (bool);

    function externalTransfer(
        address _token,
        address _feeToken,
        address _from,
        address _to,
        uint256 _value,
        uint256 _feeValue
    ) external returns (bool);

}
