// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "@openzeppelin/contracts/security/Pausable.sol";

//custom interface
import "./interfaces/IERC721.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./shared/interfaces/IKYC.sol";
import "./shared/interfaces/INextTransferRouter.sol";


  contract AstronizeCouponNFTBridge is
    EIP712,
    AccessControlEnumerable,
    Pausable
{ 
    
    string public constant PROJECT = "astronize";
    address public callHelper;
    uint256 public acceptedKycLevel;

    INextTransferRouter public nextTransferRouter;
    IKYC public kyc;



    using SafeERC20 for IERC20;

    event TreasuryAddressChanged(address indexed sender,address oldTreasuryAddress, address newTreasuryAddress);
    event Mint(address indexed sender, uint256 tokenId, address to, uint256 indexed nonce);
    event Redeem(address indexed sender, uint256 indexed nonce, uint256 tokenId);

    IERC721 public nft;

    //role init
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    //validator init
    mapping(address => bool) public trustedValidators;
    uint256 public trustedValidatorCount;

    mapping(address => mapping(uint256 => bool)) public isMintConfirmed;
    mapping(address => mapping(uint256 => bool)) public isRedeemConfirmed;


    address public astTokenAddress;
    address public treasuryAddress;
    
    uint256 mintFee = 1000000000000000000;


    modifier onlyCallHelper() {
        require(msg.sender == callHelper, "onlyCallHelper: restricted only call helper");
        _;
    }

    modifier onlyBitkubNextUser(address bitkubNextAddress) {
        require(kyc.kycsLevel(bitkubNextAddress) >= acceptedKycLevel, "onlyBitkubNextUser: restricted only Bitkub NEXT user");
        _;
    }

    constructor(
        address _callHelper,    //ใช้ของ bitkub เค้าจะ deploy แล้วส่งมาให้
        address _kyc,
        uint256 _acceptedKycLevel,
        address _nextTransferRouter, //deploy เอง

        address _nftAddress,
        address _tokenAddress,
        address _treasuryAddress
    ) EIP712("AstronizeCouponNFTBridge", "1"){

        require(_nftAddress != address(0), "token address cannot be zero");
        require(_treasuryAddress != address(0), "token address cannot be zero");

        callHelper = _callHelper;
        kyc = IKYC(_kyc);
        acceptedKycLevel = _acceptedKycLevel;

        nextTransferRouter = INextTransferRouter(_nextTransferRouter);

        nft = IERC721(_nftAddress);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());


        astTokenAddress = _tokenAddress;
        setTreasuryAddress(_treasuryAddress);
    }

    function setAcceptedKycLevel(uint256 _acceptedKycLevel) public onlyRole(DEFAULT_ADMIN_ROLE) {
        acceptedKycLevel = _acceptedKycLevel;
    }
    
    function setKyc(address _kyc) public onlyRole(DEFAULT_ADMIN_ROLE) {
        kyc = IKYC(_kyc);
    }
    
    function setCallHelper(address _callHelper) public onlyRole(DEFAULT_ADMIN_ROLE) {
        callHelper = _callHelper;
    }
    
    function setNextTransferRouter(address _nextTransferRouter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        nextTransferRouter = INextTransferRouter(_nextTransferRouter);
    }

    function getMintFee() public view returns (uint256)  {
        return mintFee;
    }

    function setMintFee(uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintFee = fee;
    }

    //for bitkubnext
    function redeemCoupon(
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signatures,
        address _bitkubnext
        ) external onlyCallHelper onlyBitkubNextUser(_bitkubnext) {
        require(deadline > block.timestamp, "deadline");

        //verify
        bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "redeemCoupon(uint256 tokenId,uint256 nonce,uint256 deadline)"
                        ),
                        tokenId,
                        nonce,
                        deadline
                    )
                )
            );

        address signer = ECDSA.recover(digest, signatures);


        require(trustedValidators[signer], "signer is not trusted validator");
        require(!isRedeemConfirmed[signer][nonce], "signer already confirmed"); 
        isRedeemConfirmed[signer][nonce] = true;

        //bitkubnext burn
        nft.burn(tokenId);        

        emit Redeem(_bitkubnext, nonce, tokenId);

    }

    function redeemCoupon(
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signatures
        ) external whenNotPaused {
        require(deadline > block.timestamp, "deadline");

        //verify
        bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "redeemCoupon(uint256 tokenId,uint256 nonce,uint256 deadline)"
                        ),
                        tokenId,
                        nonce,
                        deadline
                    )
                )
            );

        address signer = ECDSA.recover(digest, signatures);


        require(trustedValidators[signer], "signer is not trusted validator");
        require(!isRedeemConfirmed[signer][nonce], "signer already confirmed"); 
        isRedeemConfirmed[signer][nonce] = true;

        //redeem nft(burn)
        nft.burn(tokenId);        

        emit Redeem(_msgSender(), nonce, tokenId);

    }

    //for bitkubnext
    function mint(
        address to, 
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signatures,
        address _bitkubnext
        ) external onlyCallHelper onlyBitkubNextUser(_bitkubnext) {
        require(deadline > block.timestamp, "deadline");

        //verify
        bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "mint(address to,uint256 tokenId,uint256 nonce,uint256 deadline)"
                        ),
                        to,
                        tokenId,
                        nonce,
                        deadline
                    )
                )
            );

        address signer = ECDSA.recover(digest, signatures);


        require(trustedValidators[signer], "signer is not trusted validator");
        require(!isMintConfirmed[signer][nonce], "signer already confirmed"); 
        isMintConfirmed[signer][nonce] = true;

        //fee cost (ignore if mint fee = 0)  #1000000000000000000
        if (mintFee > 0) {
            nextTransferRouter.transferFrom(PROJECT, address(astTokenAddress), _bitkubnext, treasuryAddress, mintFee);
        }

        //mint nft
        nft.mint(to, tokenId);
                
        emit Mint(_bitkubnext, tokenId, to, nonce);

    }

    function mint(
        address to, 
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signatures
        ) external whenNotPaused {
        require(deadline > block.timestamp, "deadline");

        //verify
        bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "mint(address to,uint256 tokenId,uint256 nonce,uint256 deadline)"
                        ),
                        to,
                        tokenId,
                        nonce,
                        deadline
                    )
                )
            );

        address signer = ECDSA.recover(digest, signatures);


        require(trustedValidators[signer], "signer is not trusted validator");
        require(!isMintConfirmed[signer][nonce], "signer already confirmed"); 
        isMintConfirmed[signer][nonce] = true;

        //fee cost (ignore if mint fee = 0)
        if (mintFee > 0) {
            IERC20(astTokenAddress).safeTransferFrom(_msgSender(), treasuryAddress, mintFee);
        }

        //mint nft
        nft.mint(to, tokenId);
                
        emit Mint(_msgSender(), tokenId, to, nonce);

    }


    function grantTrustedValidator(address _trustedValidator) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "permission denied");

        require(_trustedValidator != address(0), "trusted validator address cannot be zero");
        require(
            !trustedValidators[_trustedValidator],
            "trusted validator already granted"
        );

        trustedValidators[_trustedValidator] = true;
        trustedValidatorCount++;
    }

    function revokeTrustedValidator(address _trustedValidator) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "permission denied");

        require(trustedValidators[_trustedValidator], "trusted validator not found");

        trustedValidators[_trustedValidator] = false;
        trustedValidatorCount--;
    }

    function _ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b + (a % b == 0 ? 0 : 1);
    }


   function setTreasuryAddress(address _newTreasuryAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _newTreasuryAddress != address(0),
            "cannot be zero"
        );

        emit TreasuryAddressChanged(msg.sender,treasuryAddress,_newTreasuryAddress);
        treasuryAddress = _newTreasuryAddress;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}