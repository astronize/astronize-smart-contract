// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


import "./interfaces/IKToken.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./token/KAP20.sol";

contract ASTToken is KAP20, AccessControlEnumerable {
    constructor(
        address admin,
        address committee,
        IKYCBitkubChain kyc,
        uint256 acceptedKycLevel
    ) KAP20("AST TOKEN", "AST", 18, admin, committee, kyc, acceptedKycLevel) {


        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address account, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        _burn(account, amount);
        return true;
    }
}