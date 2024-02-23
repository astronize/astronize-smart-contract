// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/shared/abstracts/Committee.sol

pragma solidity ^0.8.0;

abstract contract Committee {
  address public committee;

  event CommitteeSet(address indexed oldCommittee, address indexed newCommittee, address indexed caller);

  modifier onlyCommittee() {
    require(msg.sender == committee, "Committee: restricted only committee");
    _;
  }

  function setCommittee(address _committee) public virtual onlyCommittee {
    emit CommitteeSet(committee, _committee, msg.sender);
    committee = _committee;
  }
}

// File contracts/shared/interfaces/IKAP721TransferRouter.sol

pragma solidity >=0.8.0;

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

// File contracts/shared/interfaces/IKAP1155TransferRouter.sol

pragma solidity >=0.8.0;

interface IKAP1155TransferRouter {
  event InternalTransfer(
    address indexed tokenAddress,
    address indexed sender,
    address indexed recipient,
    uint256 id,
    uint256 amount
  );

  event ExternalTransfer(
    address indexed tokenAddress,
    address indexed sender,
    address indexed recipient,
    uint256 id,
    uint256 amount
  );

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
    uint256 id,
    uint256 amount
  ) external returns (bool);

  function externalTransfer(
    address tokenAddress,
    address sender,
    address recipient,
    uint256 id,
    uint256 amount
  ) external returns (bool);
}

// File contracts/shared/interfaces/IAdminKAP20Router.sol

pragma solidity >=0.6.0;

interface IAdminKAP20Router {
  function setKKUB(address _KKUB) external;

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

  function internalTransferKKUB(
    address _feeToken,
    address _from,
    address _to,
    uint256 _value,
    uint256 _feeValue
  ) external returns (bool);

  function externalTransferKKUB(
    address _feeToken,
    address _from,
    address _to,
    uint256 _value,
    uint256 _feeValue
  ) external returns (bool);

  function externalTransferKKUBToKUB(
    address _feeToken,
    address _from,
    address _to,
    uint256 _value,
    uint256 _feeValue
  ) external returns (bool);
}

// File contracts/shared/interfaces/IAdminProjectRouter.sol

pragma solidity >=0.6.0;

interface IAdminProjectRouter {
  function isSuperAdmin(address _addr, string calldata _project) external view returns (bool);

  function isAdmin(address _addr, string calldata _project) external view returns (bool);
}

// File contracts/shared/libraries/EnumerableSetAddress.sol

pragma solidity >=0.6.0;

library EnumerableSetAddress {
  struct AddressSet {
    address[] _values;
    mapping(address => uint256) _indexes;
  }

  function add(AddressSet storage set, address value) internal returns (bool) {
    if (!contains(set, value)) {
      set._values.push(value);
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  function remove(AddressSet storage set, address value) internal returns (bool) {
    uint256 valueIndex = set._indexes[value];
    if (valueIndex != 0) {
      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;
      address lastvalue = set._values[lastIndex];
      set._values[toDeleteIndex] = lastvalue;
      set._indexes[lastvalue] = toDeleteIndex + 1;
      set._values.pop();
      delete set._indexes[value];
      return true;
    } else {
      return false;
    }
  }

  function contains(AddressSet storage set, address value) internal view returns (bool) {
    return set._indexes[value] != 0;
  }

  function length(AddressSet storage set) internal view returns (uint256) {
    return set._values.length;
  }

  function at(AddressSet storage set, uint256 index) internal view returns (address) {
    require(set._values.length > index, "EnumerableSet: index out of bounds");
    return set._values[index];
  }

  function getAll(AddressSet storage set) internal view returns (address[] memory) {
    return set._values;
  }

  function get(
    AddressSet storage set,
    uint256 _page,
    uint256 _limit
  ) internal view returns (address[] memory) {
    require(_page > 0 && _limit > 0);
    uint256 tempLength = _limit;
    uint256 cursor = (_page - 1) * _limit;
    uint256 _addressLength = length(set);
    if (cursor >= _addressLength) {
      return new address[](0);
    }
    if (tempLength > _addressLength - cursor) {
      tempLength = _addressLength - cursor;
    }
    address[] memory addresses = new address[](tempLength);
    for (uint256 i = 0; i < tempLength; i++) {
      addresses[i] = at(set, cursor + i);
    }
    return addresses;
  }
}

// File contracts/modules/bitkub-nft/NextNFTTransferRouter.sol

pragma solidity 0.8.13;

abstract contract Authorization is Committee {
  IAdminProjectRouter public adminProjectRouter;
  string public constant PROJECT = "transfer-router";

  event AdminProjectRouterSet(address indexed _caller, address indexed _oldAddress, address indexed _newAddress);

  modifier onlySuperAdmin() {
    require(adminProjectRouter.isSuperAdmin(msg.sender, PROJECT), "Authorization: restricted only super admin");
    _;
  }

  modifier onlyAdmin() {
    require(adminProjectRouter.isAdmin(msg.sender, PROJECT), "Authorization: restricted only admin");
    _;
  }

  modifier onlySuperAdminOrAdmin() {
    require(
      adminProjectRouter.isSuperAdmin(msg.sender, PROJECT) || adminProjectRouter.isAdmin(msg.sender, PROJECT),
      "Authorization: restricted only super admin or admin"
    );
    _;
  }

  function setAdminProjectRouter(address _adminProjectRouter) external onlyCommittee {
    emit AdminProjectRouterSet(msg.sender, address(adminProjectRouter), _adminProjectRouter);
    adminProjectRouter = IAdminProjectRouter(_adminProjectRouter);
  }
}

contract NextNFTTransferRouter is Authorization {
  using EnumerableSetAddress for EnumerableSetAddress.AddressSet;

  mapping(string => EnumerableSetAddress.AddressSet) private _allowedTokens;
  mapping(string => EnumerableSetAddress.AddressSet) private _allowedAddresses;

  EnumerableSetAddress.AddressSet private _kTokens;
  IKAP721TransferRouter public kap721TransferRouter;
  IKAP1155TransferRouter public kap1155TransferRouter;

  event KAP721TransferRouterSet(address indexed _caller, address indexed _oldAddress, address indexed _newAddress);
  event KAP1155TransferRouterSet(address indexed _caller, address indexed _oldAddress, address indexed _newAddress);

  modifier allowedTransfer(string memory _project, address _token) {
    require(_allowedAddresses[_project].contains(msg.sender), "NextNFTTransferRouter: restricted only allowed address");
    require(_allowedTokens[_project].contains(_token), "NextNFTTransferRouter: restricted only allowed token");
    _;
  }

  constructor(
    address _adminProjectRouter,
    address _kap721TransferRouter,
    address _kap1155TransferRouter,
    address _committee
  ) {
    adminProjectRouter = IAdminProjectRouter(_adminProjectRouter);
    kap721TransferRouter = IKAP721TransferRouter(_kap721TransferRouter);
    kap1155TransferRouter = IKAP1155TransferRouter(_kap1155TransferRouter);
    committee = _committee;
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

  function setKAP721TransferRouter(address _kap721TransferRouter) external onlyCommittee {
    emit KAP721TransferRouterSet(msg.sender, address(kap721TransferRouter), _kap721TransferRouter);
    kap721TransferRouter = IKAP721TransferRouter(_kap721TransferRouter);
  }

  function setKAP1155TransferRouter(address _kap1155TransferRouter) external onlyCommittee {
    emit KAP1155TransferRouterSet(msg.sender, address(kap1155TransferRouter), _kap1155TransferRouter);
    kap1155TransferRouter = IKAP1155TransferRouter(_kap1155TransferRouter);
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

  function isAllowedAddr(string memory _project, address _addr) external view returns (bool) {
    return _allowedAddresses[_project].contains(_addr);
  }

  function allowedAddrLength(string memory _project) external view returns (uint256) {
    return _allowedAddresses[_project].length();
  }

  function allowedAddrByIndex(string memory _project, uint256 _index) external view returns (address) {
    return _allowedAddresses[_project].at(_index);
  }

  function allowedAddrByPage(
    string memory _project,
    uint256 _page,
    uint256 _limit
  ) external view returns (address[] memory) {
    return _allowedAddresses[_project].get(_page, _limit);
  }

  // onlySuperAdmin removed
  function addAddress(string memory _project, address _addr) external {
    require(_addr != address(0) && _addr != address(this), "NextNFTTransferRouter: invalid address");
    require(_allowedAddresses[_project].add(_addr), "NextNFTTransferRouter: address already exists");
  }

  // onlySuperAdmin removed
  function removeAddress(string memory _project, address _addr) external {
    require(_allowedAddresses[_project].remove(_addr), "NextNFTTransferRouter: address does not exist");
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////

  function isAllowedToken(string memory _project, address _token) external view returns (bool) {
    return _allowedTokens[_project].contains(_token);
  }

  function allowedTokenLength(string memory _project) external view returns (uint256) {
    return _allowedTokens[_project].length();
  }

  function allowedTokenByIndex(string memory _project, uint256 _index) external view returns (address) {
    return _allowedTokens[_project].at(_index);
  }

  function allowedTokenByPage(
    string memory _project,
    uint256 _page,
    uint256 _limit
  ) external view returns (address[] memory) {
    return _allowedTokens[_project].get(_page, _limit);
  }

  // onlySuperAdmin removed
  function addToken(string memory _project, address _token) external {
    require(_token != address(0) && _token != address(this), "NextNFTTransferRouter: invalid address");
    require(_allowedTokens[_project].add(_token), "NextNFTTransferRouter: address already exists");
  }

  // onlySuperAdmin removed
  function removeToken(string memory _project, address _token) external {
    require(_allowedTokens[_project].remove(_token), "NextNFTTransferRouter: address does not exist");
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////
  function transferFromKAP721(
    string memory _project,
    address _token,
    address _sender,
    address _recipient,
    uint256 _tokenId
  ) external allowedTransfer(_project, _token) {
    require(
      kap721TransferRouter.externalTransfer(_token, _sender, _recipient, _tokenId),
      "NextNFTTransferRouter: transfer KAP721 failed"
    );
  }

  function transferFromKAP1155(
    string memory _project,
    address _token,
    address _sender,
    address _recipient,
    uint256 _id,
    uint256 _amount
  ) external allowedTransfer(_project, _token) {
    require(
      kap1155TransferRouter.externalTransfer(_token, _sender, _recipient, _id, _amount),
      "NextNFTTransferRouter: transfer KAP1155 failed"
    );
  }
}
