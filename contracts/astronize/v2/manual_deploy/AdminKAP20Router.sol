

pragma solidity 0.8.10;

interface IAdminProjectRouter {
    function isSuperAdmin(address _addr, string calldata _project) external view returns (bool);

    function isAdmin(address _addr, string calldata _project) external view returns (bool);
}



abstract contract Authorization {
    IAdminProjectRouter public adminRouter;
    string public constant PROJECT = "astronize";

    modifier onlySuperAdmin() {
        require(adminRouter.isSuperAdmin(msg.sender, PROJECT), "Restricted only super admin");
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
        adminRouter = IAdminProjectRouter(_adminRouter);
    }
}



interface IKYC {
    function kycsLevel(address _addr) external view returns (uint256);
}



interface IKKUB {
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner) external view returns (uint256 balance);

    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);

    function transfer(address to, uint256 tokens) external returns (bool success);

    function approve(address spender, uint256 tokens) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function getOwner() external view returns (address);

    function batchTransfer(
        address[] calldata _from,
        address[] calldata _to,
        uint256[] calldata _value
    ) external returns (bool success);

    function adminTransfer(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function setKYC(address _kyc) external;

    function setKYCsLevel(uint256 _kycsLevel) external;

    function setAdmin(address _admin) external;

    function withdraw(uint256 _value) external;
}


interface IKToken {
    function internalTransfer(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function externalTransfer(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function mint(address account, uint256 amount) external returns (bool);

    function burn(address account, uint256 amount) external returns (bool);
}


interface IKAP20 {
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner) external view returns (uint256 balance);

    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);

    function transfer(address to, uint256 tokens) external returns (bool success);

    function approve(address spender, uint256 tokens) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function getOwner() external view returns (address);

    function adminTransfer(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}


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



contract AdminKAP20Router is Authorization, IAdminKAP20Router {
    using EnumerableSetAddress for EnumerableSetAddress.AddressSet;

    EnumerableSetAddress.AddressSet private _allowedAddr;

    IKKUB public KKUB;

    IKYC public KYC;
    uint256 public bitkubNextLevel;

    address public feeTo;
    address public committee;

    event InternalTokenTransfer(address indexed _token, address indexed _from, address indexed _to, uint256 _amount);
    event ExternalTokenTransfer(address indexed _token, address indexed _from, address indexed _to, uint256 _amount);
    event FeeTransfer(address indexed _token, address _from, address indexed _to, uint256 _amount);

    modifier onlyAllowedAddress() {
        require(_allowedAddr.contains(msg.sender), "Restricted only allowed address");
        _;
    }

    modifier onlyCommittee() {
        require(committee == msg.sender, "Restricted only committee");
        _;
    }

    receive() external payable {}

    constructor(
        address _adminRouter,
        address _committee,
        address _KKUB,
        address _KYC,
        uint256 _bitkubNextLevel
    ) public {
        adminRouter = IAdminProjectRouter(_adminRouter);
        committee = _committee;
        KKUB = IKKUB(_KKUB);
        KYC = IKYC(_KYC);
        bitkubNextLevel = _bitkubNextLevel;
        feeTo = address(this);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////

    function setKKUB(address _KKUB) external override onlySuperAdmin {
        KKUB = IKKUB(_KKUB);
    }

    function setCommittee(address _committee) external onlyCommittee {
        committee = _committee;
    }

    function setFeeTo(address _feeTo) external onlySuperAdmin {
        feeTo = _feeTo;
    }

    function setKYC(address _KYC) external onlyCommittee {
        KYC = IKYC(_KYC);
    }

    function setBitkubNextLevel(uint256 _bitkubNextLevel) external onlyCommittee {
        bitkubNextLevel = _bitkubNextLevel;
    }

    function setKYCKKUB(address _kyc) external onlyCommittee {
        KKUB.setKYC(_kyc);
    }

    function setKYCsLevelKKUB(uint256 _kycsLevel) external onlyCommittee {
        KKUB.setKYCsLevel(_kycsLevel);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////

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

    //////////////////////////////////////////////////////////////////////////////////////////////////

    function mintKToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlySuperAdmin returns (bool) {
        return IKToken(_token).mint(_account, _amount);
    }

    function burnKToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlySuperAdmin returns (bool) {
        return IKToken(_token).burn(_account, _amount);
    }

    function withdrawToken(
        address _token,
        address _to,
        uint256 _amount
    ) external onlySuperAdmin returns (bool) {
        return IKAP20(_token).transfer(_to, _amount);
    }

    function withdrawKUB(address _to, uint256 _amount) external onlySuperAdmin {
        payable(_to).transfer(_amount);
    }

    function internalTransfer(
        address _token,
        address _feeToken,
        address _from,
        address _to,
        uint256 _value,
        uint256 _feeValue
    ) external override onlyAllowedAddress returns (bool) {
        _feeTransfer(_feeToken, _from, _feeValue);
        emit InternalTokenTransfer(_token, _from, _to, _value);
        return IKToken(_token).internalTransfer(_from, _to, _value);
    }

    function externalTransfer(
        address _token,
        address _feeToken,
        address _from,
        address _to,
        uint256 _value,
        uint256 _feeValue
    ) external override onlyAllowedAddress returns (bool) {
        _feeTransfer(_feeToken, _from, _feeValue);
        emit ExternalTokenTransfer(_token, _from, _to, _value);
        return IKToken(_token).externalTransfer(_from, _to, _value);
    }

    function internalTransferKKUB(
        address _feeToken,
        address _from,
        address _to,
        uint256 _value,
        uint256 _feeValue
    ) external override onlyAllowedAddress returns (bool) {
        require(
            KYC.kycsLevel(_from) >= bitkubNextLevel && KYC.kycsLevel(_to) >= bitkubNextLevel,
            "Only internal purpose"
        );

        _feeTransfer(_feeToken, _from, _feeValue);
        emit InternalTokenTransfer(address(KKUB), _from, _to, _value);
        return KKUB.transferFrom(_from, _to, _value);
    }

    function externalTransferKKUB(
        address _feeToken,
        address _from,
        address _to,
        uint256 _value,
        uint256 _feeValue
    ) external override onlyAllowedAddress returns (bool) {
        require(KYC.kycsLevel(_from) >= bitkubNextLevel, "Only internal purpose");

        _feeTransfer(_feeToken, _from, _feeValue);
        emit ExternalTokenTransfer(address(KKUB), _from, _to, _value);
        return KKUB.transferFrom(_from, _to, _value);
    }

    function externalTransferKKUBToKUB(
        address _feeToken,
        address _from,
        address _to,
        uint256 _value,
        uint256 _feeValue
    ) external override onlyAllowedAddress returns (bool) {
        require(KYC.kycsLevel(_from) >= bitkubNextLevel, "Only internal purpose");

        _feeTransfer(_feeToken, _from, _feeValue);
        KKUB.transferFrom(_from, address(this), _value);
        KKUB.withdraw(_value);
        payable(_to).transfer(_value);
        emit ExternalTokenTransfer(address(KKUB), _from, _to, _value);
    }

    function _feeTransfer(
        address _feeToken,
        address _from,
        uint256 _feeValue
    ) internal {
        if (_feeValue > 0) {
            if (_feeToken == address(KKUB)) {
                require(KKUB.transferFrom(_from, feeTo, _feeValue));
            } else {
                require(IKToken(_feeToken).externalTransfer(_from, feeTo, _feeValue));
            }

            emit FeeTransfer(_feeToken, _from, feeTo, _feeValue);
        }
    }
}