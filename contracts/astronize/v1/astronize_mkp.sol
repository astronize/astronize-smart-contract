// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./shared/interfaces/INextTransferRouter.sol";
import "./shared/interfaces/INextNFTTransferRouter.sol";
import "./shared/interfaces/INFTResaleHandler.sol";

import "./shared/interfaces/IKYC.sol";

import "./nft/kap721/resource/interfaces/IKAP721/IKAP721Receiver.sol";


contract AstronizeMarketplace is
    Pausable,
    ERC721Holder,
    IKAP721Receiver,
    AccessControl
{
    using SafeERC20 for IERC20;

    //define event
    event Sell(
        address indexed seller,
        address indexed nftTokenAddress,
        uint256 indexed tokenId,
        address currencyTokenAddress,
        uint256 price,
        uint256 fee,
        uint256 timestamp
    );

    event Buy(
        address indexed buyer,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address currencyTokenAddress,
        address seller,
        uint256 price,
        uint256 fee,
        uint256 feeResult,
        uint256 timestamp
    );

    event Cancel(
        address indexed seller,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 timestamp
    );

    event FeeChanged(address indexed sender, uint256 oldFee, uint256 newFee);
    event MinimumSalePriceChanged(address indexed sender, uint256 oldMinimumSalePrice, uint256 newMinimumSalePrice);
    
    event TreasuryAddressChanged(address indexed sender,address oldTreasuryAddress, address newTreasuryAddress);
    event WhitelistNFTTokenUpdated(address indexed sender,address indexed nftTokenAddress, bool indexed isWhitelist);
    event WhitelistCurrencyTokenUpdated(address indexed sender,address indexed currencyTokenAddress, bool indexed isWhitelist);
  
    event AcceptedKycLevelChanged(address indexed sender, uint256 indexed oldAcceptedKycLevel, uint256 indexed newAcceptedKycLevel);
    event KycChanged(address indexed sender, address indexed oldKyc, address indexed newKyc);
    event CallHelperChanged(address indexed sender, address indexed oldCallHelper, address indexed newCallHelper);
    event NextTransferRouterChanged(address indexed sender, address indexed oldNextTransferRouter, address indexed newNextTransferRouter);
    event NextNFTTransferRouterChanged(address indexed sender, address indexed oldNextNFTTransferRouter, address indexed newNextNFTTransferRouter);
    event NFTResaleHandlerChanged(address indexed sender, address indexed oldNFTResaleHandler, address indexed newNFTResaleHandler);


    struct NFTSellInfo {
        address nftTokenAddress; //nft address
        uint256 tokenId; //nft token id

        address currencyTokenAddress; //currency ex. busd, ast, btc
        uint256 price; //sell price

        address seller; //onwer
        uint256 fee; //ast token fee
    }

    NFTSellInfo[] internal _nftInMarketplace;


    mapping(address => mapping(uint256 => uint256)) internal _indexOfTokenIds;
    
    mapping(address => bool) internal _whitelistNFTTokens;
    mapping(address => bool) internal _whitelistCurrencyTokens;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address public treasuryAddress;

    uint256 public fee; //300=3% 2deci
    uint256 public minimumSalePrice; 


    string public constant PROJECT = "astronize";
    address public callHelper;
    uint256 public acceptedKycLevel;

    INextTransferRouter public nextTransferRouterKap20;
    INextNFTTransferRouter public nextNFTTransferRouterKap721;
    IKYC public kyc;
    INFTResaleHandler public nftResaleHandler;

    modifier onlyCallHelper() {
        require(msg.sender == callHelper, "onlyCallHelper: restricted only call helper");
        _;
    }

    modifier onlyBitkubNextUser(address bitkubNextAddress) {
        require(kyc.kycsLevel(bitkubNextAddress) >= acceptedKycLevel, "onlyBitkubNextUser: restricted only Bitkub NEXT user");
        _;
    }

    constructor(
        address _callHelper,    
        address _kyc,
        uint256 _acceptedKycLevel,
        address _nextTransferRouterKap20, //kap20
        address _nextNFTTransferRouterKap721, //kap721

        address _treasuryAddress,
        uint256 _fee,
        uint256 _minimumSalePrice,
        address _nftResaleHandlerAddress

    ) {
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

        callHelper = _callHelper;
        kyc = IKYC(_kyc);
        acceptedKycLevel = _acceptedKycLevel;

        nextTransferRouterKap20 = INextTransferRouter(_nextTransferRouterKap20);
        nextNFTTransferRouterKap721 = INextNFTTransferRouter(_nextNFTTransferRouterKap721);
        nftResaleHandler = INFTResaleHandler(_nftResaleHandlerAddress);

        setTreasuryAddress(_treasuryAddress);
        setFee(_fee);
        setMinimumSalePrice(_minimumSalePrice);
    }
    
    function setNFTResaleHandler(address _nftResaleHandlerAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit NFTResaleHandlerChanged(msg.sender, address(nftResaleHandler), _nftResaleHandlerAddress);
        nftResaleHandler = INFTResaleHandler(_nftResaleHandlerAddress);
    }

    function setAcceptedKycLevel(uint256 _acceptedKycLevel) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit AcceptedKycLevelChanged(msg.sender, acceptedKycLevel, _acceptedKycLevel);
        acceptedKycLevel = _acceptedKycLevel;
    }

    function setKyc(address _kyc) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit KycChanged(_msgSender(), address(kyc), _kyc);
        kyc = IKYC(_kyc);
    }
    
    function setCallHelper(address _callHelper) external onlyRole(DEFAULT_ADMIN_ROLE) {       
        emit CallHelperChanged(_msgSender(), callHelper, _callHelper);
        callHelper = _callHelper;
    }
    
    function setNextTransferRouter(address _nextTransferRouterKap20) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit NextTransferRouterChanged(_msgSender(), address(nextTransferRouterKap20), _nextTransferRouterKap20);
        nextTransferRouterKap20 = INextTransferRouter(_nextTransferRouterKap20);
    }
    
    function setNextNFTTransferRouter(address _nextNFTTransferRouterKap721) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit NextNFTTransferRouterChanged(_msgSender(), address(_nextNFTTransferRouterKap721), _nextNFTTransferRouterKap721);
        nextNFTTransferRouterKap721 = INextNFTTransferRouter(_nextNFTTransferRouterKap721);
    }

    function setFee(uint256 _newFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newFee <= 10000, "fee must be less than 10000");

        emit FeeChanged(msg.sender,fee,_newFee);

        fee = _newFee;
    }

    function setMinimumSalePrice(uint256 _minimumSalePrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_minimumSalePrice > 0, "price must be greater than 0");

        emit MinimumSalePriceChanged(msg.sender,minimumSalePrice,_minimumSalePrice);

        minimumSalePrice = _minimumSalePrice;
    }

    function sellNFT(
        address nftTokenAddress,
        uint256 tokenId,
        address currencyTokenAddress,
        uint256 price,
        address _bitkubnext
    ) external onlyCallHelper onlyBitkubNextUser(_bitkubnext) whenNotPaused {

        require(price > minimumSalePrice, "price must be greater than the minimum sale price");
        require(isWhitelistNFTToken(nftTokenAddress),"nft token address not whitelisted");
        require(isWhitelistCurrencyToken(currencyTokenAddress),"currency token address not whitelisted");
        require(nftResaleHandler.canSell(nftTokenAddress, tokenId), "this nft can't sell");

        //bitkubnext transfer
        nextNFTTransferRouterKap721.transferFromKAP721(PROJECT, address(nftTokenAddress), _bitkubnext, address(this), tokenId);


        _nftInMarketplace.push(
            NFTSellInfo({
                nftTokenAddress : nftTokenAddress,  
                tokenId: tokenId,
                currencyTokenAddress : currencyTokenAddress,  
                price: price,
                seller: _bitkubnext,
                fee: fee
            })
        );

        _indexOfTokenIds[nftTokenAddress][tokenId] = _nftInMarketplace.length - 1;
        emit Sell(_bitkubnext, nftTokenAddress, tokenId, currencyTokenAddress, price, fee,  block.timestamp);

    }

    function sellNFT(
        address nftTokenAddress,
        uint256 tokenId,
        address currencyTokenAddress,
        uint256 price
    ) external whenNotPaused{

        require(price > minimumSalePrice, "price must be greater than the minimum sale price");
        require(isWhitelistNFTToken(nftTokenAddress),"nft token address not whitelisted");
        require(isWhitelistCurrencyToken(currencyTokenAddress),"currency token address not whitelisted");
        require(nftResaleHandler.canSell(nftTokenAddress, tokenId), "this nft can't sell");

        IERC721(nftTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        _nftInMarketplace.push(
            NFTSellInfo({
                nftTokenAddress : nftTokenAddress,  
                tokenId: tokenId,
                currencyTokenAddress : currencyTokenAddress,  
                price: price,
                seller: msg.sender,
                fee: fee
            })
        );

        _indexOfTokenIds[nftTokenAddress][tokenId] = _nftInMarketplace.length - 1;
        emit Sell(msg.sender, nftTokenAddress, tokenId, currencyTokenAddress, price, fee,  block.timestamp);

    }

    function cancel(address nftTokenAddress, uint256 tokenId, address _bitkubnext)
         external onlyCallHelper onlyBitkubNextUser(_bitkubnext) 
    {
        NFTSellInfo memory item = itemByTokenId(nftTokenAddress, tokenId);
        require(item.seller == _bitkubnext, "only seller can cancel");
       
        _removeItemByIndex(indexByTokenId(nftTokenAddress, tokenId));
        
        IERC721(nftTokenAddress).safeTransferFrom(
            address(this),
            item.seller,
            item.tokenId
        );

        emit Cancel(_bitkubnext, nftTokenAddress, tokenId, block.timestamp);
    }

    function cancel(address nftTokenAddress, uint256 tokenId)
        external
    {
        NFTSellInfo memory item = itemByTokenId(nftTokenAddress, tokenId);
        require(item.seller == msg.sender, "only seller can cancel");
       
        _removeItemByIndex(indexByTokenId(nftTokenAddress, tokenId));
        
        IERC721(nftTokenAddress).safeTransferFrom(
            address(this),
            item.seller,
            item.tokenId
        );

        emit Cancel(msg.sender, nftTokenAddress, tokenId, block.timestamp);
    }


    function buyNFT(address nftTokenAddress, uint256 tokenId, address currencyTokenAddress, uint256 price, address _bitkubnext) external onlyCallHelper onlyBitkubNextUser(_bitkubnext) whenNotPaused{
        NFTSellInfo memory item = itemByTokenId(nftTokenAddress, tokenId);

        require(item.price == price, "price must match");
        require(item.currencyTokenAddress == currencyTokenAddress, "currency token address must match");

        //cal fee
        uint256 toTreasury = _calculateFee(item.price, item.fee);

        //fee (bitkubnext transfer)
        nextTransferRouterKap20.transferFrom(PROJECT, address(item.currencyTokenAddress), _bitkubnext, treasuryAddress, toTreasury);
        nextTransferRouterKap20.transferFrom(PROJECT, address(item.currencyTokenAddress), _bitkubnext, item.seller, item.price - toTreasury);

        _removeItemByIndex(indexByTokenId(nftTokenAddress, tokenId));

        IERC721(nftTokenAddress).safeTransferFrom(
            address(this),
            _bitkubnext,
            tokenId
        );

        //update sell status
        nftResaleHandler.setSold(nftTokenAddress, tokenId);

        emit Buy(
            _bitkubnext,
            nftTokenAddress,
            tokenId,
            currencyTokenAddress,
            item.seller,
            item.price,
            item.fee,
            toTreasury,
            block.timestamp
        );

    }

    function buyNFT(address nftTokenAddress, uint256 tokenId, address currencyTokenAddress, uint256 price) external whenNotPaused {
        NFTSellInfo memory item = itemByTokenId(nftTokenAddress, tokenId);

        require(item.price == price, "price must match");
        require(item.currencyTokenAddress == currencyTokenAddress, "currency token address must match");

        //cal fee
        uint256 toTreasury = _calculateFee(item.price, item.fee);

        //fee
        IERC20(item.currencyTokenAddress).safeTransferFrom(msg.sender, treasuryAddress, toTreasury);

        IERC20(item.currencyTokenAddress).safeTransferFrom(msg.sender, item.seller, item.price - toTreasury);

        _removeItemByIndex(indexByTokenId(nftTokenAddress, tokenId));

        IERC721(nftTokenAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        emit Buy(
            msg.sender,
            nftTokenAddress,
            tokenId,
            currencyTokenAddress,
            item.seller,
            item.price,
            item.fee,
            toTreasury,
            block.timestamp
        );

    }
    
   function setTreasuryAddress(address _newTreasuryAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _newTreasuryAddress != address(0),
            "cannot be zero"
        );

        emit TreasuryAddressChanged(msg.sender,treasuryAddress,_newTreasuryAddress);
        treasuryAddress = _newTreasuryAddress;
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

    function setWhitelistCurrencyToken(address currencyTokenAddress, bool isWhitelist)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(currencyTokenAddress != address(0), "token address cannot be zero");
        _whitelistCurrencyTokens[currencyTokenAddress] = isWhitelist;

        emit WhitelistCurrencyTokenUpdated(msg.sender, currencyTokenAddress, isWhitelist);
    }

    function isWhitelistCurrencyToken(address currencyTokenAddress) public view returns (bool) {
        return _whitelistCurrencyTokens[currencyTokenAddress];
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function itemByTokenId(address nftTokenAddress, uint256 tokenId)
        public
        view
        returns (NFTSellInfo memory)
    {
        require(
            IERC721(nftTokenAddress).ownerOf(tokenId) == address(this),
            "tokenId is not owned by this contract"
        );
        uint256 index = indexByTokenId(nftTokenAddress, tokenId);
        NFTSellInfo memory item = _nftInMarketplace[index];
        require(item.tokenId == tokenId, "item not found");
        return item;
    }

    function itemByIndex(uint256 index) public view returns (NFTSellInfo memory) {
        return _nftInMarketplace[index];
    }

     function itemInMarketplace() external view returns (NFTSellInfo[] memory) {
        return _nftInMarketplace;
    }

    function indexByTokenId(address nftTokenAddress, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            IERC721(nftTokenAddress).ownerOf(tokenId) == address(this),
            "tokenId is not owned by this contract"
        );
        return _indexOfTokenIds[nftTokenAddress][tokenId];
    }

    function itemCount() external view returns (uint256) {
        return _nftInMarketplace.length;
    }

    // internal functions
    function _removeItemByIndex(uint256 index) internal {
        _nftInMarketplace[index] = _nftInMarketplace[_nftInMarketplace.length - 1];
        _indexOfTokenIds[_nftInMarketplace[index].nftTokenAddress][_nftInMarketplace[index].tokenId] = index;
        delete _nftInMarketplace[_nftInMarketplace.length - 1];
        _nftInMarketplace.pop();
    }

    function _calculateFee(uint256 _price, uint256 _fee)
        internal
        pure
        returns (uint256)
    {
        return (_price * _fee) / 10000;
    }

    function onKAP721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns  (bytes4) {
        return this.onKAP721Received.selector;
    }
}