// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "../shared/abstracts/standard/Authorization.sol";
import "../shared/abstracts/KYCHandler.sol";

abstract contract BitkubChain is Authorization, KYCHandler {
    address public committee;

    function setKYC(address _kyc) public onlyCommittee {
        _setKYC(IKYCBitkubChain(_kyc));
    }

    function setAcceptedKycLevel(uint256 _kycLevel) public onlyCommittee {
        _setAcceptedKycLevel(_kycLevel);
    }

    function setCommittee(address _committee) external onlyCommittee {
        committee = _committee;
    }

    modifier onlyCommittee() {
        require(msg.sender == committee, "Restricted only committee");
        _;
    }
   
}
