// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "@openzeppelin/contracts/security/Pausable.sol";

//custom interface
// import "./kap721/interfaces/IKAP721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./shared/interfaces/IKYC.sol";
import "./shared/interfaces/INextTransferRouter.sol";


interface IKAP721 {
    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function ownerOf(uint256 _tokenId) external view returns (address);

    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external;
}

  contract AstronizeNFTBridge is
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
    event Mint(address indexed sender, uint256 tokenId, address to, uint256 indexed nonce, address nftAddress);
    event Redeem(address indexed sender, uint256 indexed nonce, uint256 tokenId, address nftAddress);
    event WhitelistNFTTokenUpdated(address indexed sender,address indexed nftTokenAddress, bool indexed isWhitelist);

    mapping(address => bool) internal _whitelistNFTTokens;

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

        address _tokenAddress,
        address _treasuryAddress
    ) EIP712("AstronizeNFTBridge", "1"){

        require(_treasuryAddress != address(0), "token address cannot be zero");

        callHelper = _callHelper;
        kyc = IKYC(_kyc);
        acceptedKycLevel = _acceptedKycLevel;

        nextTransferRouter = INextTransferRouter(_nextTransferRouter);


        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());


        astTokenAddress = _tokenAddress;

        setTreasuryAddress(_treasuryAddress);
    }

    function setASTTokenAddress(address _tokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        astTokenAddress = _tokenAddress;
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

    function setWhitelistNFTToken(address nftTokenAddress, bool isWhitelist)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(nftTokenAddress != address(0), "token address cannot be zero");
        _whitelistNFTTokens[nftTokenAddress] = isWhitelist;

        emit WhitelistNFTTokenUpdated(msg.sender, nftTokenAddress, isWhitelist);
    }

    function isWhitelistNFTToken(address nftTokenAddress) public view returns (bool) {
        return _whitelistNFTTokens[nftTokenAddress];
    }

    //for bitkubnext
    function redeemForBitkubNext(
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline,
        address nftAddress,
        bytes calldata signatures,
        address _bitkubnext
        ) external onlyCallHelper onlyBitkubNextUser(_bitkubnext) {
        require(deadline > block.timestamp, "deadline");
        require(nftAddress != address(0), "token address cannot be zero");

        require(
                isWhitelistNFTToken(nftAddress),
                "nft token address not whitelisted"
            );

        IKAP721 nft = IKAP721(nftAddress);
        
        require( nft.ownerOf(tokenId) == _bitkubnext, "owner is not match");

        //verify
        bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "redeem(uint256 tokenId,uint256 nonce,uint256 deadline,address nftAddress)"
                        ),
                        tokenId,
                        nonce,
                        deadline,
                        nftAddress
                    )
                )
            );

        address signer = ECDSA.recover(digest, signatures);


        require(trustedValidators[signer], "signer is not trusted validator");
        require(!isRedeemConfirmed[signer][nonce], "signer already confirmed"); 
        isRedeemConfirmed[signer][nonce] = true;

        //bitkubnext burn
        nft.burn(tokenId);        

        emit Redeem(_bitkubnext, nonce, tokenId, nftAddress);

    }

    function redeem(
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline,
        address nftAddress,
        bytes calldata signatures
        ) external whenNotPaused {
        require(deadline > block.timestamp, "deadline");
        require(nftAddress != address(0), "token address cannot be zero");
        require(
                isWhitelistNFTToken(nftAddress),
                "nft token address not whitelisted"
            );

        IKAP721 nft = IKAP721(nftAddress);
        
        require( nft.getApproved(tokenId) == address(this), "nft address not approved");
        require( nft.ownerOf(tokenId) == _msgSender(), "owner is not match");

        //verify
        bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "redeem(uint256 tokenId,uint256 nonce,uint256 deadline,address nftAddress)"
                        ),
                        tokenId,
                        nonce,
                        deadline,
                        nftAddress
                    )
                )
            );

        address signer = ECDSA.recover(digest, signatures);


        require(trustedValidators[signer], "signer is not trusted validator");
        require(!isRedeemConfirmed[signer][nonce], "signer already confirmed"); 
        isRedeemConfirmed[signer][nonce] = true;

        //redeem nft(burn)
        nft.burn(tokenId);        

        emit Redeem(_msgSender(), nonce, tokenId, nftAddress);

    }

    // for bitkubnext (remove)
    // function mint(NFTMintParam calldata data, string memory tokenUri, bytes calldata signatures, address _bitkubnext) external onlyCallHelper onlyBitkubNextUser(_bitkubnext) {
    //     require(data.deadline > block.timestamp, "deadline");
    //     require(data.nftAddress != address(0), "token address cannot be zero");
    //     require(
    //             isWhitelistNFTToken(data.nftAddress),
    //             "nft token address not whitelisted"
    //         );

    //     IKAP721 nft = IKAP721(data.nftAddress);

    //     //verify
    //     bytes32 digest = _hashTypedDataV4(
    //             keccak256(
    //                 abi.encode(
    //                     keccak256(
    //                         "mint(address to,uint256 tokenId,uint256 nonce,uint256 deadline,string tokenUri,address nftAddress)"
    //                     ),
    //                     data.to,
    //                     data.tokenId,
    //                     data.nonce,
    //                     data.deadline,
    //                     keccak256(bytes(tokenUri)),
    //                     data.nftAddress
    //                 )
    //             )
    //         );

    //     address signer = ECDSA.recover(digest, signatures);


    //     require(trustedValidators[signer], "signer is not trusted validator");
    //     require(!isMintConfirmed[signer][data.nonce], "signer already confirmed"); 
    //     isMintConfirmed[signer][data.nonce] = true;

    //     //fee cost (ignore if mint fee = 0)  #1000000000000000000
    //     if (mintFee > 0) {
    //         nextTransferRouter.transferFrom(PROJECT, address(astTokenAddress), _bitkubnext, treasuryAddress, mintFee);
    //     }

    //     //mint nft
    //     nft.mint(data.to, data.tokenId);
    //     nft.setTokenURI(data.tokenId, tokenUri);
        
    //     emit Mint(_bitkubnext, data.tokenId, data.to, data.nonce, data.nftAddress);

    // }


    struct NFTMintWithSignParam {
        address to; 
        uint256 tokenId;
        uint256 nonce;
        uint256 deadline;
        address nftAddress;
        string tokenUri;
        bytes signatures;
    }   


    function mint(NFTMintWithSignParam[] calldata data) external whenNotPaused {
                for (uint i=0; i<data.length; i++) {

                    require(data[i].deadline > block.timestamp, "deadline");
                    require(data[i].nftAddress != address(0), "token address cannot be zero");
                    require(
                            isWhitelistNFTToken(data[i].nftAddress),
                            "nft token address not whitelisted"
                        );

                    IKAP721 nft = IKAP721(data[i].nftAddress);

                    //verify
                    bytes32 digest = _hashTypedDataV4(
                            keccak256(
                                abi.encode(
                                    keccak256(
                                        "mint(address to,uint256 tokenId,uint256 nonce,uint256 deadline,string tokenUri,address nftAddress)"
                                    ),
                                    data[i].to,
                                    data[i].tokenId,
                                    data[i].nonce,
                                    data[i].deadline,
                                    keccak256(bytes(data[i].tokenUri)),
                                    data[i].nftAddress
                                )
                            )
                        );


                    address signer = ECDSA.recover(digest, data[i].signatures);

                    require(trustedValidators[signer], "signer is not trusted validator");
                    require(!isMintConfirmed[signer][data[i].nonce], "signer already confirmed"); 
                    isMintConfirmed[signer][data[i].nonce] = true;

                    // server mint (no fee)
                    // fee cost (ignore if mint fee = 0)
                    // if (mintFee > 0) {
                    //     IERC20(astTokenAddress).safeTransferFrom(_msgSender(), treasuryAddress, mintFee);
                    // }

                    // //mint nft
                    nft.mint(data[i].to, data[i].tokenId);
                    nft.setTokenURI(data[i].tokenId, data[i].tokenUri);
                
                    emit Mint(_msgSender(), data[i].tokenId, data[i].to, data[i].nonce, data[i].nftAddress);
                }

    }

    function tokensOfOwner(address contractAddress, address owner) external view returns (uint[] memory) {

        uint balance = IERC721Enumerable(contractAddress).balanceOf(owner);

        uint[] memory tokens = new uint[](balance);

        for (uint i=0; i<balance; i++) {
            tokens[i] = (IERC721Enumerable(contractAddress).tokenOfOwnerByIndex(owner, i));
        }

        return tokens;
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