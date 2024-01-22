// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./abstracts/AstronizeBitkubBase.sol";
import "./shared/interfaces/IKAP721/IKAP721.sol";
import "./shared/interfaces/INextNFTTransferRouter.sol";
import "./shared/abstracts/KAP721Holder.sol";

contract AstronizeAuction is AstronizeBitkubBase, KAP721Holder {
    event NextNFTTransferRouterSet(
        address indexed caller,
        address indexed oldAddress,
        address indexed newAddress
    );
    event TreasuryAddressSet(address indexed from, address indexed to);
    event WhitelistedTokenSet(
        address indexed tokenAddress,
        bool value,
        uint256 step
    );
    event WhitelistedNftSet(address indexed nftAddress, bool value);
    event Sell(
        address indexed sender,
        address indexed nftAddress,
        uint256 indexed tokenId,
        Item item,
        uint256 timestamp
    );
    event Cancel(
        address indexed sender,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address tokenAddress,
        address sellerAddress,
        address bidderAddress,
        uint256 price,
        uint256 timestamp
    );
    event Bid(
        address indexed sender,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address tokenAddress,
        address sellerAddress,
        uint256 price,
        uint256 endAt,
        address previousBidderAddress,
        uint256 previousPrice,
        uint256 timestamp
    );
    event Claim(
        address indexed sender,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address tokenAddress,
        address sellerAddress,
        address bidderAddress,
        uint256 price,
        uint256 timestamp
    );
    event ItemEdited(
        address indexed sender,
        address indexed nftAddress,
        uint256 indexed tokenId,
        Item item,
        uint256 timestamp
    );
    event FeePercentageSet(address indexed sender, uint256 value);
    event ExtendedDurationSet(address indexed sender, uint256 value);
    event MinDurationSet(address indexed sender, uint256 value);

    enum ItemStatus {
        None,
        Active,
        Claimed,
        Canceled
    }

    struct Item {
        address tokenAddress;
        address sellerAddress;
        address bidderAddress;
        uint256 price;
        uint256 startAt;
        uint256 endAt;
        ItemStatus status;
    }

    INextNFTTransferRouter public nextNFTTransferRouter;
    mapping(address => mapping(uint256 => Item)) internal _items;
    mapping(address => bool) internal _whitelistedNfts;

    struct WhitelistedToken {
        bool isActive;
        uint256 step;
    }

    mapping(address => WhitelistedToken) internal _whitelistedTokens;
    address public treasuryAddress;
    uint256 public feePercentage;
    uint256 public extendedDuration;
    uint256 public minDuration;

    constructor(
        address _adminProjectRouter,
        address _kyc,
        address _committee,
        uint256 _acceptedKycLevel,
        address _ownerAccessControlRouter,
        address _nextTransferRouter,
        address _nextNFTTransferRouter,
        address _treasuryAddress,
        address _callHelper
    ) {
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

        // init
        nextNFTTransferRouter = INextNFTTransferRouter(_nextNFTTransferRouter);
        treasuryAddress = _treasuryAddress;
        callHelper = _callHelper;
        minDuration = 5 minutes;
    }

    /**
     * @notice whitelisted NFT
     */
    function whitelistedNftOf(address _nftAddress) public view returns (bool) {
        return _whitelistedNfts[_nftAddress];
    }

    /**
     * @notice whitelisted token
     */
    function whitelistedTokenOf(
        address _tokenAddress
    ) public view returns (WhitelistedToken memory) {
        return _whitelistedTokens[_tokenAddress];
    }

    /**
     * @notice get item
     */
    function itemOf(
        address _nftAddress,
        uint256 _tokenId
    ) public view returns (Item memory) {
        return _items[_nftAddress][_tokenId];
    }

    /**
     * @notice set fee percentage
     */
    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10000, "fee greater than 100%");
        feePercentage = _feePercentage;
        emit FeePercentageSet(msg.sender, _feePercentage);
    }

    /**
     * @notice set extended duration
     */
    function setExtendedDuration(uint256 _extendedDuration) external onlyOwner {
        extendedDuration = _extendedDuration;
        emit ExtendedDurationSet(msg.sender, _extendedDuration);
    }

    /**
     * @notice set minimum duration
     */
    function setMinDuration(uint256 _minDuration) external onlyOwner {
        minDuration = _minDuration;
        emit MinDurationSet(msg.sender, _minDuration);
    }

    /**
     * @notice set treasury address
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        require(_treasuryAddress != address(0), "cannot be zero address");
        emit TreasuryAddressSet(treasuryAddress, _treasuryAddress);
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @notice set whitelisted token (KAP20)
     */
    function setWhitelistedToken(
        address _address,
        bool _isActive,
        uint256 _step
    ) external onlyOwner {
        _whitelistedTokens[_address] = WhitelistedToken({
            isActive: _isActive,
            step: _step
        });

        emit WhitelistedTokenSet(_address, _isActive, _step);
    }

    /**
     * @notice set whitelisted NFT (KAP721)
     */
    function setWhitelistedNft(
        address _address,
        bool isActive
    ) external onlyOwner {
        _whitelistedNfts[_address] = isActive;

        emit WhitelistedNftSet(_address, isActive);
    }

    /**
     * @notice set next NFT transfer router
     */
    function setNextNFTTransferRouter(
        address _nextNFTTransferRouter
    ) external onlyOwner {
        emit NextNFTTransferRouterSet(
            msg.sender,
            address(nextNFTTransferRouter),
            _nextNFTTransferRouter
        );
        nextNFTTransferRouter = INextNFTTransferRouter(_nextNFTTransferRouter);
    }

    /**
     * @notice edit item
     */
    function editItemForAdmin(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _startAt,
        uint256 _endAt,
        ItemStatus _status
    ) external onlyModerator {
        Item storage _item = _items[_nftAddress][_tokenId];
        _item.startAt = _startAt;
        _item.endAt = _endAt;
        _item.status = _status;

        emit ItemEdited(
            msg.sender,
            _nftAddress,
            _tokenId,
            _item,
            block.timestamp
        );
    }

    /**
     * @notice sell
     */
    function sell(
        address _nftAddress,
        uint256 _tokenId,
        address _tokenAddress,
        uint256 _price,
        uint256 _startAt,
        uint256 _endAt
    ) external {
        // transfer NFT
        IKAP721(_nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        // sell
        _sell(
            _nftAddress,
            _tokenId,
            _tokenAddress,
            _price,
            _startAt,
            _endAt,
            msg.sender
        );
    }

    /**
     * @notice sell for Bitkub Next
     */
    function sellForBitkubNext(
        address _nftAddress,
        uint256 _tokenId,
        address _tokenAddress,
        uint256 _price,
        uint256 _beginAt,
        uint256 _endAt,
        address _bitkubNext
    ) external onlyCallHelper onlyBitkubNextUser(_bitkubNext) {
        // transfer nft
        nextNFTTransferRouter.transferFromKAP721(
            PROJECT,
            _nftAddress,
            _bitkubNext,
            address(this),
            _tokenId
        );

        // sell
        _sell(
            _nftAddress,
            _tokenId,
            _tokenAddress,
            _price,
            _beginAt,
            _endAt,
            _bitkubNext
        );
    }

    /**
     * @notice sell
     */
    function _sell(
        address _nftAddress,
        uint256 _tokenId,
        address _tokenAddress,
        uint256 _price,
        uint256 _startAt,
        uint256 _endAt,
        address _user
    ) internal whenNotPaused {
        // check start at
        if (_startAt < block.timestamp) {
            _startAt = block.timestamp;
        }

        // check time
        require(_startAt < _endAt, "startAt must be less than endAt");
        require(_endAt >= block.timestamp + minDuration, "endAt");
        require(
            _endAt < block.timestamp + (90 days),
            "endAt must be less than 60 days"
        );
        require((_endAt - _startAt) >= minDuration, "duration");

        // check nft and token
        require(_whitelistedNfts[_nftAddress], "whitelisted NFT");
        WhitelistedToken storage _whitelistedToken = _whitelistedTokens[
            _tokenAddress
        ];
        require(_price % _whitelistedToken.step == 0, "price step");
        require(_whitelistedToken.isActive, "whitelisted token");

        // store item
        Item memory _item = Item({
            sellerAddress: _user,
            tokenAddress: _tokenAddress,
            price: _price,
            startAt: _startAt,
            endAt: _endAt,
            bidderAddress: address(0),
            status: ItemStatus.Active
        });
        _items[_nftAddress][_tokenId] = _item;

        // event
        emit Sell(_user, _nftAddress, _tokenId, _item, block.timestamp);
    }

    /**
     * @notice bid
     */
    function bid(
        address _nftAddress,
        uint256 _tokenId,
        address _tokenAddress,
        uint256 _price
    ) external {
        _bid(_nftAddress, _tokenId, _tokenAddress, _price, msg.sender);
    }

    /**
     * @notice bid for Bitkub Next
     */
    function bidForBitkubNext(
        address _nftAddress,
        uint256 _tokenId,
        address _tokenAddress,
        uint256 _price,
        address _bitkubNext
    ) external onlyCallHelper onlyBitkubNextUser(_bitkubNext) {
        _bid(_nftAddress, _tokenId, _tokenAddress, _price, _bitkubNext);
    }

    /**
     * @notice bid
     */
    function _bid(
        address _nftAddress,
        uint256 _tokenId,
        address _tokenAddress,
        uint256 _price,
        address _user
    ) internal whenNotPaused {
        // check item
        Item storage _item = _items[_nftAddress][_tokenId];
        require(!isExpired(_nftAddress, _tokenId), "expired");
        require(block.timestamp >= _item.startAt, "startAt");
        require(_item.price < _price, "require higher price");
        require(_item.status == ItemStatus.Active, "status");
        require(_tokenAddress == _item.tokenAddress, "tokenAddress");

        // check step
        WhitelistedToken storage _whitelistedToken = _whitelistedTokens[
            _tokenAddress
        ];
        require(_price % _whitelistedToken.step == 0, "price step");

        // transfer token to previous bidder
        if (_item.bidderAddress != address(0)) {
            IKAP20(_tokenAddress).transfer(_item.bidderAddress, _item.price);
        }

        // transfer token
        _transferToken(_user, address(this), _tokenAddress, _price);

        // get previous price and bidder
        uint256 previousPrice = _item.price;
        address previousBidderAddress = _item.bidderAddress;

        // set new price and bidder
        _item.price = _price;
        _item.bidderAddress = _user;

        // check endAt for extended time
        if (_item.endAt < block.timestamp + extendedDuration) {
            _item.endAt = block.timestamp + extendedDuration;
        }

        emit Bid(
            _user,
            _nftAddress,
            _tokenId,
            _item.tokenAddress,
            _item.bidderAddress,
            _item.price,
            _item.endAt,
            previousBidderAddress,
            previousPrice,
            block.timestamp
        );
    }

    /**
     * @notice cancel
     */
    function cancel(
        address _nftAddress,
        uint256 _tokenId
    ) external whenNotPaused {
        // check item
        Item storage _item = _items[_nftAddress][_tokenId];
        require(msg.sender == _item.sellerAddress, "invalid owner");
        require(_item.bidderAddress == address(0), "already bade");
        require(_item.status == ItemStatus.Active, "status");

        // cancel
        _cancel(_nftAddress, _tokenId);

        emit Cancel(
            msg.sender,
            _nftAddress,
            _tokenId,
            _item.tokenAddress,
            _item.sellerAddress,
            _item.bidderAddress,
            _item.price,
            block.timestamp
        );
    }

    /**
     * @notice cancel for Bitkub Next
     */
    function cancelForBitkubNext(
        address _nftAddress,
        uint256 _tokenId,
        address _bitkubNext
    ) external onlyCallHelper onlyBitkubNextUser(_bitkubNext) whenNotPaused {
        // check item
        Item storage _item = _items[_nftAddress][_tokenId];
        require(_bitkubNext == _item.sellerAddress, "invalid owner");
        require(_item.bidderAddress == address(0), "already bade");
        require(_item.status == ItemStatus.Active, "status");

        // cancel
        _cancel(_nftAddress, _tokenId);

        emit Cancel(
            _bitkubNext,
            _nftAddress,
            _tokenId,
            _item.tokenAddress,
            _item.sellerAddress,
            _item.bidderAddress,
            _item.price,
            block.timestamp
        );
    }

    /**
     * @notice cancel for admin
     */
    function cancelForAdmin(
        address _nftAddress,
        uint256 _tokenId
    ) external onlyModerator {
        _cancel(_nftAddress, _tokenId);

        Item storage _item = _items[_nftAddress][_tokenId];
        emit Cancel(
            msg.sender,
            _nftAddress,
            _tokenId,
            _item.tokenAddress,
            _item.sellerAddress,
            _item.bidderAddress,
            _item.price,
            block.timestamp
        );
    }

    /**
     * @notice cancel
     */
    function _cancel(address _nftAddress, uint256 _tokenId) internal {
        // set item
        Item storage _item = _items[_nftAddress][_tokenId];
        _item.status = ItemStatus.Canceled;

        // transfer token to previous bidder
        if (_item.bidderAddress != address(0)) {
            IKAP20(_item.tokenAddress).transfer(
                _item.bidderAddress,
                _item.price
            );
        }

        // transfer NFT to owner
        IKAP721(_nftAddress).safeTransferFrom(
            address(this),
            _item.sellerAddress,
            _tokenId
        );
    }

    /**
     * @notice claim
     */
    function claim(address _nftAddress, uint256 _tokenId) external {
        _claim(_nftAddress, _tokenId, msg.sender);
    }

    /**
     * @notice claim for Bitkub Next
     */
    function claimForBitkubNext(
        address _nftAddress,
        uint256 _tokenId,
        address _bitkubNext
    ) external onlyCallHelper onlyBitkubNextUser(_bitkubNext) {
        _claim(_nftAddress, _tokenId, _bitkubNext);
    }

    /**
     * @notice claim
     */
    function _claim(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) internal whenNotPaused {
        // check expire time
        require(isExpired(_nftAddress, _tokenId), "time");

        // check item
        Item storage _item = _items[_nftAddress][_tokenId];
        require(_item.status == ItemStatus.Active, "status");
        _item.status = ItemStatus.Claimed;

        // transfer nft to bidder
        IKAP721(_nftAddress).safeTransferFrom(
            address(this),
            _item.bidderAddress,
            _tokenId
        );

        // transfer token to Seller
        (uint256 _sellerPrice, uint256 _fee) = _splitPrice(
            _item.price,
            feePercentage
        );
        IKAP20(_item.tokenAddress).transfer(_item.sellerAddress, _sellerPrice);
        if (_fee > 0) {
            IKAP20(_item.tokenAddress).transfer(treasuryAddress, _fee);
        }

        emit Claim(
            _user,
            _nftAddress,
            _tokenId,
            _item.tokenAddress,
            _item.sellerAddress,
            _item.bidderAddress,
            _item.price,
            block.timestamp
        );
    }

    /**
     * @notice check expired
     */
    function isExpired(
        address nftAddress,
        uint256 _tokenId
    ) public view returns (bool) {
        if (_items[nftAddress][_tokenId].endAt < block.timestamp) {
            return true;
        }

        return false;
    }

    /**
     * @notice split price
     */
    function _splitPrice(
        uint256 _finalPrice,
        uint256 _feePercentage
    ) internal pure returns (uint256, uint256) {
        uint256 _fee = (_finalPrice * _feePercentage) / 10000;

        return (_finalPrice - _fee, _fee);
    }
}
