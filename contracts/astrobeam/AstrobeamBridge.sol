// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./abstracts/AstronizeBitkubBase.sol";
import "./shared/interfaces/IKAP20/IKAP20.sol";
import "./shared/interfaces/IOwnerAccessControlRouter.sol";
import "./interfaces/IAdminKAP20Router.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AstrobeamBridge is EIP712, Pausable, AstronizeBitkubBase {
    using EnumerableSet for EnumerableSet.AddressSet;

    event Withdrawal(
        address indexed toAddress,
        address indexed tokenAddress,
        uint256 indexed nonce,
        uint256 amount,
        uint256 fee,
        uint256 deadline,
        address[] validators
    );
    event Deposit(
        address indexed toAddress,
        address indexed tokenAddress,
        uint256 indexed nonce,
        uint256 amount,
        uint256 fee,
        uint256 deadline,
        address[] validators
    );
    event ValidatorGranted(address indexed sender, address validator);
    event ValidatorRevoked(address indexed sender, address validator);
    event AdminTokenRecovery(
        address tokenAddress,
        uint256 amount,
        address toAddress
    );
    event NonceSet(uint256 indexed nonce, bool from, bool to);
    event TokenTransferForAdmin(
        address indexed sender,
        address indexed tokenAddress,
        uint256 amount,
        address to
    );
    event TreasuryAddressSet(address indexed sender, address from, address to);
    event RequestSet(
        address indexed sender,
        address[] tokenAddress,
        bool isAllowed
    );

    mapping(address => mapping(address => bool)) internal _requests; // mapping user => token => isAllowed
    mapping(uint256 => bool) internal _nonces;
    EnumerableSet.AddressSet internal _validators;
    mapping(address => mapping(uint256 => bool)) internal _nonceValidators;
    address public treasuryAddress;

    constructor(
        address _adminProjectRouter,
        address _kyc,
        address _committee,
        uint256 _acceptedKycLevel,
        address _ownerAccessControlRouter,
        address _nextTransferRouter,
        address _treasuryAddress,
        address _callHelper
    ) EIP712("AstrobeamBridge", "1") {
        // Initialize BitkubChain
        PROJECT = "astronize";
        adminProjectRouter = IAdminProjectRouter(_adminProjectRouter);
        kyc = IKYCBitkubChain(_kyc);
        committee = _committee;
        acceptedKycLevel = _acceptedKycLevel;
        ownerAccessControlRouter = IOwnerAccessControlRouter(
            _ownerAccessControlRouter
        );
        nextTransferRouter = INextTransferRouter(_nextTransferRouter);
        treasuryAddress = _treasuryAddress;
        callHelper = _callHelper;
    }

    /**
     * @notice set request
     */
    function setRequest(
        address[] calldata _tokenAddresses,
        bool _isAllowed
    ) external {
        for (uint i = 0; i < _tokenAddresses.length; i++) {
            _requests[msg.sender][_tokenAddresses[i]] = _isAllowed;
        }

        emit RequestSet(msg.sender, _tokenAddresses, _isAllowed);
    }

    /**
     * @notice set request for Bitkub Next
     */
    function setRequestForBitkubNext(
        address[] calldata _tokenAddresses,
        bool _isAllowed,
        address _bitkubNext
    ) external onlyCallHelper onlyBitkubNextUser(_bitkubNext) {
        for (uint i = 0; i < _tokenAddresses.length; i++) {
            _requests[_bitkubNext][_tokenAddresses[i]] = _isAllowed;
        }

        emit RequestSet(_bitkubNext, _tokenAddresses, _isAllowed);
    }

    /**
     * @notice get request
     */
    function requestOf(
        address _user,
        address _tokenAddress
    ) public view returns (bool) {
        return _requests[_user][_tokenAddress];
    }

    /**
     * @notice set treasury address
     * @param _treasuryAddress: treasury address
     * @dev Only callable by owner.
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        emit TreasuryAddressSet(msg.sender, treasuryAddress, _treasuryAddress);
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @notice get nonce
     */
    function nonceOf(uint256 _nonce) public view returns (bool) {
        return _nonces[_nonce];
    }

    /**
     * @notice set nonce for cancel
     * @param _nonce: nonce
     * @param _value: value
     * @dev Only callable by owner.
     */
    function setNonce(uint256 _nonce, bool _value) external onlyOwner {
        emit NonceSet(_nonce, _nonces[_nonce], _value);
        _nonces[_nonce] = _value;
    }

    /**
     * @notice is validator
     */
    function isValidator(address _addr) public view returns (bool) {
        return _validators.contains(_addr);
    }

    /**
     * @notice get validators
     */
    function getValidators(
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (address[] memory) {
        require(endIndex >= startIndex, "Invalid range");

        uint256 setLength = _validators.length();
        uint256 actualEndIndex = endIndex > setLength ? setLength : endIndex;
        uint256 size = actualEndIndex - startIndex;

        address[] memory elements = new address[](size);

        for (uint256 i = 0; i < size; i++) {
            elements[i] = _validators.at(startIndex + i);
        }

        return elements;
    }

    /**
     * @notice get nonce of validator
     */
    function nonceValidatorOf(
        address _addr,
        uint256 _nonce
    ) public view returns (bool) {
        return _nonceValidators[_addr][_nonce];
    }

    /**
     * @notice withdraw token from bridge
     * @param _tokenAddress: token address
     * @param _amount: amount
     * @param _feeTokenAddress: fee token address
     * @param _nonce: nonce
     * @param _fee: fee
     * @param _deadline: transaction deadline
     * @param _signatures: signature from validator
     * @param _toAddress: target address
     */
    function withdraw(
        address _tokenAddress,
        uint256 _amount,
        address _feeTokenAddress,
        uint256 _fee,
        uint256 _nonce,
        uint256 _deadline,
        bytes[] calldata _signatures,
        address _toAddress
    ) external onlyOperator {
        _initProccess(_nonce, _deadline, _signatures);

        address[] memory validators_ = new address[](_signatures.length);
        for (uint256 i = 0; i < _signatures.length; i++) {
            bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "withdraw(address tokenAddress,uint256 amount,address feeTokenAddress,uint256 fee,uint256 nonce,uint256 deadline,address toAddress)"
                        ),
                        _tokenAddress,
                        _amount,
                        _feeTokenAddress,
                        _fee,
                        _nonce,
                        _deadline,
                        _toAddress
                    )
                )
            );

            validators_[i] = _validateSigner(digest, _signatures[i], _nonce);
        }

        // transfer token
        IKAP20(_tokenAddress).transfer(_toAddress, _amount);
        // transfer fee
        if (_fee > 0) {
            require(
                requestOf(_toAddress, _feeTokenAddress),
                "fee token request"
            );
            _transferToken(_toAddress, treasuryAddress, _feeTokenAddress, _fee);
        }

        emit Withdrawal(
            _toAddress,
            _tokenAddress,
            _nonce,
            _amount,
            _fee,
            _deadline,
            validators_
        );
    }

    /**
     * @notice deposit token to bridge
     * @param _tokenAddress: token address
     * @param _amount: amount
     * @param _feeTokenAddress: fee token address
     * @param _fee: fee
     * @param _nonce: nonce
     * @param _deadline: transaction deadline
     * @param _signatures: signature from validator
     * @param _fromAddress: target address
     */
    function deposit(
        address _tokenAddress,
        uint256 _amount,
        address _feeTokenAddress,
        uint256 _fee,
        uint256 _nonce,
        uint256 _deadline,
        bytes[] calldata _signatures,
        address _fromAddress
    ) external onlyOperator {
        require(requestOf(_fromAddress, _tokenAddress), "token request");
        _initProccess(_nonce, _deadline, _signatures);

        address[] memory validators_ = new address[](_signatures.length);
        for (uint256 i = 0; i < _signatures.length; i++) {
            bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "deposit(address tokenAddress,uint256 amount,address feeTokenAddress,uint256 fee,uint256 nonce,uint256 deadline,address fromAddress)"
                        ),
                        _tokenAddress,
                        _amount,
                        _feeTokenAddress,
                        _fee,
                        _nonce,
                        _deadline,
                        _fromAddress
                    )
                )
            );

            validators_[i] = _validateSigner(digest, _signatures[i], _nonce);
        }

        // transfer token
        _transferToken(_fromAddress, address(this), _tokenAddress, _amount);
        // transfer fee
        if (_fee > 0) {
            require(
                requestOf(_fromAddress, _feeTokenAddress),
                "fee token request"
            );

            _transferToken(
                _fromAddress,
                treasuryAddress,
                _feeTokenAddress,
                _fee
            );
        }

        emit Deposit(
            _fromAddress,
            _tokenAddress,
            _nonce,
            _amount,
            _fee,
            _deadline,
            validators_
        );
    }

    /**
     * @notice grant validator
     * @param _validator: the address of validator
     * @dev Only callable by owner.
     */
    function grantValidator(address _validator) external onlyOwner {
        require(_validators.add(_validator), "already exist");
        emit ValidatorGranted(msg.sender, _validator);
    }

    /**
     * @notice revoke validator
     * @param _validator: the address of validator
     * @dev Only callable by owner.
     */
    function revokeValidator(address _validator) external onlyOwner {
        require(_validators.remove(_validator), "not found");
        emit ValidatorRevoked(msg.sender, _validator);
    }

    // internal function
    function _ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b + (a % b == 0 ? 0 : 1);
    }

    /**
     * @notice init process to validate deadline and signers
     */
    function _initProccess(
        uint256 _nonce,
        uint256 _deadline,
        bytes[] calldata _signatures
    ) internal {
        require(_deadline > block.timestamp, "deadline");
        require(_validators.length() >= 3, "require at least 3 validators");
        require(
            _signatures.length >= _ceilDiv(_validators.length(), 2),
            "require at least half of validators to be validated"
        );
        require(!_nonces[_nonce], "nonce has already been used");
        _nonces[_nonce] = true;
    }

    /**
     * @notice validate signer
     */
    function _validateSigner(
        bytes32 digest,
        bytes calldata _signatures,
        uint256 _nonce
    ) internal returns (address) {
        address signer = ECDSA.recover(digest, _signatures);
        require(_validators.contains(signer), "signer is not validator");
        require(
            !_nonceValidators[signer][_nonce],
            "validator has already been used"
        );
        _nonceValidators[signer][_nonce] = true;
        return signer;
    }

    /**
     * @notice It allows the admin to recover token from this contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverToken(
        address _tokenAddress,
        uint256 _tokenAmount,
        address _toAddress
    ) external onlyOwner {
        IKAP20(_tokenAddress).transfer(_toAddress, _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount, _toAddress);
    }
}
