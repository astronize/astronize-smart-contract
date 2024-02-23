// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./abstracts/AstronizeBitkubBase.sol";
import "./shared/interfaces/IKAP721/IKAP721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./shared/interfaces/IKAP20/IKAP20.sol";
import "./shared/interfaces/INextNFTTransferRouter.sol";
import "./shared/interfaces/IKAP721/IKAP721.sol";

contract AstronizeOffer is AstronizeBitkubBase {
    event OfferCreated(
        uint256 indexed tokenId,
        address indexed nftAddress,
        address indexed offerorAddress,
        Offer offer,
        uint256 timestamp
    );
    event OfferAccepted(
        uint256 indexed tokenId,
        address indexed nftAddress,
        address indexed offerorAddress,
        address sellerAddress,
        Offer offer,
        uint256 timestamp
    );
    event OfferCanceled(
        uint256 indexed tokenId,
        address indexed nftAddress,
        address indexed offerorAddress,
        Offer offer,
        uint256 timestamp
    );
    event TreasuryAddressSet(address indexed from, address indexed to);
    event NextNFTTransferRouterSet(
        address indexed caller,
        address indexed oldAddress,
        address indexed newAddress
    );
    event FeePercentageSet(address indexed sender, uint256 value);

    enum OfferStatus {
        None,
        Created,
        Accepted,
        Canceled
    }

    struct Offer {
        address tokenAddress;
        uint256 amount;
        uint256 endAt;
        OfferStatus status;
    }

    // mapping offerorAddress => nftAddress => tokenId => Offer
    mapping(address => mapping(address => mapping(uint256 => Offer)))
        internal _offers;
    address public treasuryAddress;
    uint256 public feePercentage;
    INextNFTTransferRouter public nextNFTTransferRouter;

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
     * @notice set fee percentage
     */
    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10000, "fee greater than 100%");
        feePercentage = _feePercentage;
        emit FeePercentageSet(msg.sender, _feePercentage);
    }

    /**
     * @notice offer of
     */
    function offerOf(
        address _offerorAddress,
        address _nftAddress,
        uint256 _tokenId
    ) public view returns (Offer memory) {
        return _offers[_offerorAddress][_nftAddress][_tokenId];
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
     * @notice make offer
     */
    function makeOffer(
        uint256 _tokenId,
        address _nftAddress,
        address _tokenAddress,
        uint256 _amount,
        uint256 _endAt
    ) external {
        _makeOffer(
            _tokenId,
            _nftAddress,
            _tokenAddress,
            _amount,
            _endAt,
            msg.sender
        );
    }

    /**
     * @notice make offer for Bitkub Next
     */
    function makeOfferForBitkubNext(
        uint256 _tokenId,
        address _nftAddress,
        address _tokenAddress,
        uint256 _amount,
        uint256 _endAt,
        address _bitkubNext
    ) external onlyCallHelper onlyBitkubNextUser(_bitkubNext) {
        _makeOffer(
            _tokenId,
            _nftAddress,
            _tokenAddress,
            _amount,
            _endAt,
            _bitkubNext
        );
    }

    /**
     * @dev make offer
     */
    function _makeOffer(
        uint256 _tokenId,
        address _nftAddress,
        address _tokenAddress,
        uint256 _amount,
        uint256 _endAt,
        address _offerorAddress
    ) internal {
        require(_endAt <= block.timestamp + (366 days), "offer: max duration");
        require(
            IKAP20(_tokenAddress).balanceOf(_offerorAddress) >= _amount,
            "offer: balance"
        );

        Offer storage _offer = _offers[_offerorAddress][_nftAddress][_tokenId];

        _offer.tokenAddress = _tokenAddress;
        _offer.amount = _amount;
        _offer.endAt = _endAt;
        _offer.status = OfferStatus.Created;

        emit OfferCreated(
            _tokenId,
            _nftAddress,
            _offerorAddress,
            _offer,
            block.timestamp
        );
    }

    /**
     * @notice accept offer
     */
    function acceptOffer(
        uint256 _tokenId,
        address _nftAddress,
        address _tokenAddress,
        uint256 _amount,
        address _offerorAddress
    ) external {
        // transfer NFT
        IKAP721(_nftAddress).safeTransferFrom(
            msg.sender,
            _offerorAddress,
            _tokenId
        );
        // accept offer
        _acceptOffer(
            _tokenId,
            _nftAddress,
            _tokenAddress,
            _amount,
            _offerorAddress,
            msg.sender
        );
    }

    /**
     * @notice accept offer for bitkub next
     */
    function acceptOfferForBitkubNext(
        uint256 _tokenId,
        address _nftAddress,
        address _tokenAddress,
        uint256 _amount,
        address _offerorAddress,
        address _bitkubNext
    ) external onlyCallHelper onlyBitkubNextUser(_bitkubNext) {
        // transfer NFT
        nextNFTTransferRouter.transferFromKAP721(
            PROJECT,
            _nftAddress,
            _bitkubNext,
            _offerorAddress,
            _tokenId
        );
        // accept offer
        _acceptOffer(
            _tokenId,
            _nftAddress,
            _tokenAddress,
            _amount,
            _offerorAddress,
            _bitkubNext
        );
    }

    /**
     * @dev accept offer
     */
    function _acceptOffer(
        uint256 _tokenId,
        address _nftAddress,
        address _tokenAddress,
        uint256 _amount,
        address _offerorAddress,
        address _sellerAddress
    ) internal {
        Offer storage _offer = _offers[_offerorAddress][_nftAddress][_tokenId];

        require(_offer.status == OfferStatus.Created, "offer: status");
        require(_offer.tokenAddress == _tokenAddress, "offer: token address");
        require(_offer.amount == _amount, "offer: amount");
        require(_offer.endAt >= block.timestamp, "offer: endAt");
        _offer.status = OfferStatus.Accepted;

        // transfer token
        _transferTokens(
            _offerorAddress,
            _sellerAddress,
            _tokenAddress,
            _amount
        );

        emit OfferAccepted(
            _tokenId,
            _nftAddress,
            _offerorAddress,
            _sellerAddress,
            _offer,
            block.timestamp
        );
    }

    /**
     * @notice cancel offer
     */
    function cancelOffer(uint256 _tokenId, address _nftAddress) external {
        _cancelOffer(_tokenId, _nftAddress, msg.sender);
    }

    /**
     * @notice cancel offer for bitkub next
     */
    function cancelOfferForBitkubNext(
        uint256 _tokenId,
        address _nftAddress,
        address _bitkubNext
    ) external onlyCallHelper onlyBitkubNextUser(_bitkubNext) {
        _cancelOffer(_tokenId, _nftAddress, _bitkubNext);
    }

    /**
     * @notice cancel offer
     */
    function _cancelOffer(
        uint256 _tokenId,
        address _nftAddress,
        address _offerorAddress
    ) internal {
        Offer storage _offer = _offers[_offerorAddress][_nftAddress][_tokenId];
        _offer.status = OfferStatus.Canceled;

        emit OfferCanceled(
            _tokenId,
            _nftAddress,
            _offerorAddress,
            _offer,
            block.timestamp
        );
    }

    // internal
    /**
     * @notice transfer tokens
     */
    function _transferTokens(
        address _offerorAddress,
        address _sellerAddress,
        address _tokenAddress,
        uint256 _amount
    ) internal {
        (uint256 _sellerPrice, uint256 _fee) = _splitPrice(
            _amount,
            feePercentage
        );

        // transfer token
        _transferToken(
            _offerorAddress,
            _sellerAddress,
            _tokenAddress,
            _sellerPrice
        );

        // transfer fee
        if (_fee > 0) {
            _transferToken(
                _offerorAddress,
                treasuryAddress,
                _tokenAddress,
                _fee
            );
        }
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
