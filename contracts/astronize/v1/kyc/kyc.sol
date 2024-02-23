// Sources flattened with hardhat v2.4.0 https://hardhat.org

// File contracts/interfaces/IAdmin.sol

pragma solidity 0.8.10;

interface IAdmin {
  function isSuperAdmin(address _addr) external view returns (bool);

  function isAdmin(address _addr) external view returns (bool);
}

// File contracts/KYCBitkubChainV2.sol

pragma solidity 0.8.10;

contract KYCBitkubChainV2 {
  IAdmin public admin;

  mapping(address => uint256) public kycsLevel;
  mapping(address => bool) public isAddressKyc;
  address[] public kycAddresses;

  // projectName => functionName => KYC Levels
  mapping(string => mapping(string => uint256)) public kycsProjectLevel;

  mapping(string => uint256) public kycTitleToLevel;
  mapping(uint256 => string) public kycLevelToTitle;

  uint256 public version = 2;

  event KycCompleted(address indexed addr, address indexed caller, uint256 previousLevel, uint256 level);
  event KycRevoked(address indexed addr, address indexed caller, uint256 previousLevel, uint256 level);

  event KycProject(address indexed _caller, string projectName, string functionName, uint256 level);
  event KycTitle(address indexed _caller, string title, uint256 level);

  modifier onlySuperAdmin() {
    require(admin.isSuperAdmin(msg.sender), "Restrict only super admin");
    _;
  }

  modifier onlyAdmin() {
    require(
      admin.isSuperAdmin(msg.sender) || admin.isAdmin(msg.sender),
      "Restrict only address is admin smart contract"
    );
    _;
  }

  constructor(address _admin) public {
    admin = IAdmin(_admin);
  }

  function kycAddressesLength() external view returns (uint256) {
    return kycAddresses.length;
  }

  // onlySuperAdmin removed
  function setAdmin(address _admin) external {
    admin = IAdmin(_admin);
  }

  function _isPowerOfTwo(uint256 n) private pure returns (bool) {
    return n > 0 ? (n & (n - 1)) == 0 : false;
  }

  // onlySuperAdmin removed
  function setKycTitle(string calldata _title, uint256 _level) external {
    require(_isPowerOfTwo(_level), "Level must be power of 2");

    kycTitleToLevel[_title] = _level;
    kycLevelToTitle[_level] = _title;

    emit KycTitle(msg.sender, _title, _level);
  }

  // onlySuperAdmin removed
  function setKycProjectLevel(
    string calldata _projectName,
    string calldata _functionName,
    uint256 kycsLevel_
  ) external {
    kycsProjectLevel[_projectName][_functionName] = kycsLevel_;
    emit KycProject(msg.sender, _projectName, _functionName, kycsLevel_);
  }

  // onlyAdmin removed
  function setKycCompleted(address _addr, uint256 _level) public {
    _setKycCompleted(_addr, _level);
  }

  // onlyAdmin removed
  function batchSetKycCompleted(address[] calldata _addrs, uint256 level) external {
    for (uint256 i = 0; i < _addrs.length; i++) {
      _setKycCompleted(_addrs[i], level);
    }
  }

  function _setKycCompleted(address _addr, uint256 _level) internal {
    if (_level > 1) {
      uint256 previousLevel = kycsLevel[_addr];
      kycsLevel[_addr] = _level;

      if (!isAddressKyc[_addr]) {
        kycAddresses.push(_addr);
        isAddressKyc[_addr] = true;
      }

      emit KycCompleted(_addr, msg.sender, previousLevel, _level);
    }
  }

  // onlyAdmin removed
  // No kyc level set to no kyc
  function setKycRevoked(address _addr) external {
    _setKycRevoked(_addr);
  }

  // onlyAdmin removed
  function batchSetKycRevoked(address[] calldata _addrs) external {
    for (uint256 i = 0; i < _addrs.length; i++) {
      _setKycRevoked(_addrs[i]);
    }
  }

  function _setKycRevoked(address _addr) internal {
    uint256 previousLevel = kycsLevel[_addr];
    kycsLevel[_addr] = 0;
    emit KycRevoked(_addr, msg.sender, previousLevel, 0);
  }
}
