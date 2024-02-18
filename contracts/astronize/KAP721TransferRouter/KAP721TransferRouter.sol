// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/interfaces/IAdminProjectRouter.sol


pragma solidity 0.8.13;

interface IAdminProjectRouter {
    function isSuperAdmin(address _addr, string calldata _project) external view returns (bool);

    function isAdmin(address _addr, string calldata _project) external view returns (bool);
}


// File contracts/abstracts/AuthorizationNFT.sol


pragma solidity 0.8.13;

abstract contract AuthorizationNFT {
    IAdminProjectRouter public adminRouter;
    string public constant PROJECT = "nft-transfer";

    event SetAdmin(address indexed oldAdmin, address indexed newAdmin, address indexed caller);

    modifier onlySuperAdmin() {
        require(adminRouter.isSuperAdmin(msg.sender, PROJECT), "Restricted only super admin");
        _;
    }

    modifier onlyAdmin() {
        require(adminRouter.isAdmin(msg.sender, PROJECT), "Restricted only admin");
        _;
    }

    modifier onlySuperAdminOrAdmin() {
        require(
            adminRouter.isSuperAdmin(msg.sender, PROJECT) || adminRouter.isAdmin(msg.sender, PROJECT),
            "Restricted only super admin or admin"
        );
        _;
    }

    function setAdmin(address _adminRouter) external onlySuperAdmin {
        emit SetAdmin(address(adminRouter), _adminRouter, msg.sender);
        adminRouter = IAdminProjectRouter(_adminRouter);
    }
}


// File contracts/interfaces/IKAP721TransferRouter.sol


pragma solidity 0.8.13;

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


// File contracts/interfaces/token/IKAP165.sol


pragma solidity 0.8.13;

interface IKAP165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File contracts/interfaces/token/IKAP721.sol


pragma solidity 0.8.13;

interface IKAP721 is IKAP165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function adminTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function internalTransfer(
        address sender,
        address recipient,
        uint256 tokenId
    ) external returns (bool);

    function externalTransfer(
        address sender,
        address recipient,
        uint256 tokenId
    ) external returns (bool);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File contracts/libraries/EnumerableSetAddress.sol


pragma solidity 0.8.13;

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


// File contracts/helper/KAP721TransferRouter.sol


pragma solidity 0.8.13;



contract KAP721TransferRouter is IKAP721TransferRouter, AuthorizationNFT {
    using EnumerableSetAddress for EnumerableSetAddress.AddressSet;

    bytes4 public constant INTERFACE_ID_KAP721 = 0xf422ea4e;

    EnumerableSetAddress.AddressSet private _allowedAddr;

    constructor(address adminRouter_) {
        adminRouter = IAdminProjectRouter(adminRouter_);
    }

    modifier onlyAllowedAddress() {
        require(_allowedAddr.contains(msg.sender), "KAP721TransferRouter : Restricted only allowed address");
        _;
    }

    function isAllowedAddr(address _addr) external view override returns (bool) {
        return _allowedAddr.contains(_addr);
    }

    function allowedAddrLength() external view override returns (uint256) {
        return _allowedAddr.length();
    }

    function allowedAddrByIndex(uint256 _index) external view override returns (address) {
        return _allowedAddr.at(_index);
    }

    function allowedAddrByPage(uint256 _page, uint256 _limit) external view override returns (address[] memory) {
        return _allowedAddr.get(_page, _limit);
    }

    function addAddress(address _addr) external override onlySuperAdminOrAdmin {
        require(_addr != address(0) && _addr != address(this), "Invalid address");
        require(_allowedAddr.add(_addr), "Address already exists");
    }

    function revokeAddress(address _addr) external override onlySuperAdmin {
        require(_allowedAddr.remove(_addr), "Address does not exist");
    }

    function internalTransfer(
        address tokenAddress,
        address sender,
        address recipient,
        uint256 id
    ) external override onlyAllowedAddress returns (bool) {
        if (IKAP165(tokenAddress).supportsInterface(INTERFACE_ID_KAP721) == true) {
            IKAP721(tokenAddress).internalTransfer(sender, recipient, id);
        } else {
            IKAP721(tokenAddress).transferFrom(sender, recipient, id);
        }
        emit InternalTransfer(tokenAddress, sender, recipient, id);
        return true;
    }

    function externalTransfer(
        address tokenAddress,
        address sender,
        address recipient,
        uint256 id
    ) external override onlyAllowedAddress returns (bool) {
        if (IKAP165(tokenAddress).supportsInterface(INTERFACE_ID_KAP721) == true) {
            IKAP721(tokenAddress).externalTransfer(sender, recipient, id);
        } else {
            IKAP721(tokenAddress).transferFrom(sender, recipient, id);
        }
        emit ExternalTransfer(tokenAddress, sender, recipient, id);
        return true;
    }
}