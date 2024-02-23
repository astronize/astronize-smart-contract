// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File contracts/interfaces/IAdminProject.sol

pragma solidity 0.8.19;

interface IAdminProject {
  function rootAdmin() external view returns (address);

  function isSuperAdmin(address _addr, string calldata _project) external view returns (bool);

  function isAdmin(address _addr, string calldata _project) external view returns (bool);
}

// File contracts/libraries/EnumerableSetAddress.sol

pragma solidity 0.8.19;

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

// File contracts/AdminProject.sol

pragma solidity 0.8.19;

contract AdminProject is IAdminProject {
  using EnumerableSetAddress for EnumerableSetAddress.AddressSet;

  bytes32 public adminChangeKey;
  address public override rootAdmin;

  mapping(address => string) public superAdminProject;
  mapping(address => string) public adminProject;
  mapping(string => EnumerableSetAddress.AddressSet) private _projectSuperAdmin;
  mapping(string => EnumerableSetAddress.AddressSet) private _projectAdmin;
  event RoleGranted(address indexed account, address indexed sender);
  event RoleRevoked(address indexed account, address indexed sender);

  modifier onlyRootAdmin() {
    require(msg.sender == rootAdmin, "Only Root can add super admin");
    _;
  }

  constructor(
    address _root
    // , bytes32 _adminChangeKey
    ) public {
    rootAdmin = _root;
    // adminChangeKey = _adminChangeKey;
  }


  function changeRoot(
    address _newAdmin,
    bytes32 _keyData,
    bytes32[] memory merkleProof,
    bytes32 _newRootKey
  ) public {
    // bytes32 leaf = keccak256(abi.encodePacked(msg.sender, "BitkubAdminProject", _keyData));
    // require(verify(adminChangeKey, leaf, merkleProof), "Invalid proof.");
    require(msg.sender == rootAdmin, "Not allowed");
    rootAdmin = _newAdmin;
    // adminChangeKey = _newRootKey;
  }

  function isSuperAdmin(address _addr, string calldata _project) external view override returns (bool) {
    return (keccak256(bytes(superAdminProject[_addr])) == keccak256(bytes(_project)));
  }

  function isAdmin(address _addr, string calldata _project) external view override returns (bool) {
    return (keccak256(bytes(adminProject[_addr])) == keccak256(bytes(_project)));
  }

  // onlyRootAdmin removed
  function addAdmin(address _addr, string calldata _project) external {
    require(bytes(superAdminProject[_addr]).length == 0 && bytes(adminProject[_addr]).length == 0, "Already set admin");
    adminProject[_addr] = _project;
    _projectAdmin[_project].add(_addr);
    emit RoleGranted(_addr, msg.sender);
  }

  // onlyRootAdmin removed
  function revokeAdmin(address _addr, string calldata _project) external {
    adminProject[_addr] = "";
    _projectAdmin[_project].remove(_addr);
    emit RoleRevoked(_addr, msg.sender);
  }

  // onlyRootAdmin removed
  function addSuperAdmin(address _addr, string calldata _project) external {
    require(bytes(superAdminProject[_addr]).length == 0 && bytes(adminProject[_addr]).length == 0, "Already set admin");
    superAdminProject[_addr] = _project;
    _projectSuperAdmin[_project].add(_addr);
    emit RoleGranted(_addr, msg.sender);
  }

  // onlyRootAdmin removed
  function revokeSuperAdmin(address _addr, string calldata _project) external {
    superAdminProject[_addr] = "";
    _projectSuperAdmin[_project].remove(_addr);
    emit RoleRevoked(_addr, msg.sender);
  }

  function getAdminLength(string calldata _project) external view returns (uint256) {
    return _projectAdmin[_project].length();
  }

  function getAdminProject(
    string calldata _project,
    uint256 _page,
    uint256 _limit
  ) external view returns (address[] memory) {
    return _projectAdmin[_project].get(_page, _limit);
  }

  function getSuperAdminLength(string calldata _project) external view returns (uint256) {
    return _projectSuperAdmin[_project].length();
  }

  function getSuperAdminProject(
    string calldata _project,
    uint256 _page,
    uint256 _limit
  ) external view returns (address[] memory) {
    return _projectSuperAdmin[_project].get(_page, _limit);
  }
}
