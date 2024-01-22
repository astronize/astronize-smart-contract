// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

interface IAdminProject {
    function rootAdmin() external view returns (address);

    function isSuperAdmin(address _addr, string calldata _project) external view returns (bool);

    function isAdmin(address _addr, string calldata _project) external view returns (bool);
}
