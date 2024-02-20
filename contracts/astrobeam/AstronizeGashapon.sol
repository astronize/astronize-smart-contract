// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./abstracts/AstronizeBitkubBase.sol";
import "./shared/interfaces/IKAP721/IKAP721.sol";
import "./shared/abstracts/KAP721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AstronizeGashapon is AstronizeBitkubBase, KAP721Holder {
    using EnumerableSet for EnumerableSet.AddressSet;

    event TreasuryAddressSet(address indexed from, address indexed to);
    event CollectionCreated(
        address indexed sender,
        uint256 indexed collectionId,
        Collection collection,
        uint256 timestamp
    );
    event Purchase(
        address indexed sender,
        uint256 indexed collectionId,
        bytes32 indexed hashedSeed,
        address nftAddress,
        uint256[] tokenIds,
        uint256 remainingAmount,
        address tokenAddress,
        uint256 price,
        uint256 timestamp
    );
    event NftAdded(
        address indexed sender,
        uint256 indexed collectionId,
        uint256[] tokenIds,
        uint256 remainingAmount,
        uint256 timestamp
    );
    event NftRemoved(
        address indexed sender,
        uint256 indexed collectionId,
        uint256[] tokenIds,
        uint256 remainingAmount,
        uint256 timestamp
    );
    event CollectionEdited(
        address indexed sender,
        uint256 indexed collectionId,
        Collection collection,
        uint256 timestamp
    );
    event RequestSet(
        address indexed sender,
        uint256 indexed colectionId,
        bytes32 indexed hashedSeed,
        address tokenAddress,
        uint256 price,
        uint256 amount,
        uint256 timestamp
    );
    event MaxPurchaseAmountSet(
        uint256 maxPurchaseAmount
    );

    struct Collection {
        address nftAddress;
        address tokenAddress;
        uint256 price;
        bool isActive;
        uint256[] tokenIds;
    }
    uint256 public idCounter;
    // collection id => collection
    mapping(uint256 => Collection) internal _collections;
    uint256 public nonce;
    address public treasuryAddress;
    struct Request {
        address tokenAddress;
        uint256 price;
        uint256 amount;
        uint256 revealBlock;
        bool isPending;
        bytes32 hashedSeed;
    }
    // user address => collection id => request
    mapping(address => mapping(uint256 => Request)) internal _requests;
    uint256 public maxPurchaseAmount;

    constructor(
        address _adminProjectRouter,
        address _kyc,
        address _committee,
        uint256 _acceptedKycLevel,
        address _ownerAccessControlRouter,
        address _nextTransferRouter,
        address _treasuryAddress,
        address _callHelper,
        uint256 _maxPurchaseAmount
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

        treasuryAddress = _treasuryAddress;
        callHelper = _callHelper;

        maxPurchaseAmount = _maxPurchaseAmount;
    }

    /**
     * @notice get collection
     */
    function collectionOf(
        uint256 _collectionId
    ) external view returns (Collection memory) {
        return _collections[_collectionId];
    }

    /**
     * @notice get request
     */
    function requestOf(
        address _user,
        uint256 _collectionId
    ) external view returns (Request memory) {
        return _requests[_user][_collectionId];
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
     * @notice set max purchase amount
    */
    function setMaxPurchase(uint256 _maxPurchaseAmount) external onlyOwner {
        maxPurchaseAmount = _maxPurchaseAmount;
        emit MaxPurchaseAmountSet(_maxPurchaseAmount);
    }

    /**
     * @notice create collection for gashapon
     */
    function createCollection(
        address _nftAddress,
        address _tokenAddress,
        uint256 _price,
        bool _isActive
    ) external onlyModerator {
        Collection memory _collection = Collection({
            nftAddress: _nftAddress,
            tokenAddress: _tokenAddress,
            price: _price,
            isActive: _isActive,
            tokenIds: new uint256[](0)
        });

        idCounter++;
        _collections[idCounter] = _collection;

        emit CollectionCreated(
            msg.sender,
            idCounter,
            _collection,
            block.timestamp
        );
    }

    /**
     * @notice edit collection for gashapon
     */
    function editCollection(
        uint256 _collectionId,
        bool _isActive
    ) external onlyModerator {
        // get collection
        Collection storage _collection = _collections[_collectionId];

        // set collection
        _collection.isActive = _isActive;

        emit CollectionEdited(
            msg.sender,
            _collectionId,
            _collection,
            block.timestamp
        );
    }

    /**
     * @notice add nfts to collection
     */
    function addNfts(
        uint256 _collectionId,
        uint256[] calldata _tokenIds
    ) external onlyModerator {
        // get collection
        Collection storage _collection = _collections[_collectionId];

        // add NFTs
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IKAP721(_collection.nftAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
            _collection.tokenIds.push(_tokenIds[i]);
        }

        emit NftAdded(
            msg.sender,
            _collectionId,
            _tokenIds,
            _collection.tokenIds.length,
            block.timestamp
        );
    }

    /**
     * @notice remove nfts to collection
     */
    function removeNfts(
        uint256 _collectionId,
        uint256 _startIndex,
        uint256 _endIndex
    ) external onlyModerator {
        // get collection
        Collection storage _collection = _collections[_collectionId];

        // remove NFTs
        uint256 _amount = _endIndex - _startIndex + 1;
        uint256[] memory _tokenIds = new uint256[](_amount);
        for (uint256 i = _endIndex; i >= _startIndex; i--) {
            // remove
            uint256 _tokenId = _collection.tokenIds[i];
            _removeItemByIndex(_collection.tokenIds, i);

            // transfer
            IKAP721(_collection.nftAddress).safeTransferFrom(
                address(this),
                msg.sender,
                _tokenId
            );

            _tokenIds[i] = _tokenId;
            if(i==0) break;
        }

        emit NftRemoved(
            msg.sender,
            _collectionId,
            _tokenIds,
            _collection.tokenIds.length,
            block.timestamp
        );
    }

    /**
     * @notice set request
     */
    function setRequest(
        uint256 _collectionId,
        address _tokenAddress,
        uint256 _price,
        uint256 _amount,
        bytes32 _hashedSeed
    ) external {
        _setRequest(_collectionId, _tokenAddress, _price, _amount, _hashedSeed, msg.sender);
    }

    /**
     * @notice set request for Bitkub Next
     */
    function setRequestForBitkubNext(
        uint256 _collectionId,
        address _tokenAddress,
        uint256 _price,
        uint256 _amount,
        bytes32 _hashedSeed,
        address _bitkubNext
    ) external onlyCallHelper onlyBitkubNextUser(_bitkubNext) {
        _setRequest(_collectionId, _tokenAddress, _price, _amount, _hashedSeed, _bitkubNext);
    }

    /**
     * @notice set request
     */
    function _setRequest(
        uint256 _collectionId,
        address _tokenAddress,
        uint256 _price,
        uint256 _amount,
        bytes32 _hashedSeed,
        address _user
    ) internal whenNotPaused{
        require(_amount<=maxPurchaseAmount,"max purchase amount");

        Request storage _request = _requests[_user][_collectionId];
        require(!_request.isPending, "already request");

        Collection memory _collection = _collections[_collectionId];
        require(_collection.isActive,"active");
        require(_collection.tokenIds.length >= _amount, "nft not enough");
        require(_collection.price == _price, "price");

        _request.amount = _amount;
        _request.price = _price;
        _request.tokenAddress = _tokenAddress;
        _request.revealBlock = block.number + 1;
        _request.hashedSeed = _hashedSeed;
        _request.isPending = true;

        // transfer token
        _transferToken(_user, treasuryAddress, _collection.tokenAddress, _collection.price * _amount);

        emit RequestSet(
            _user,
            _collectionId,
            _hashedSeed,
            _tokenAddress,
            _price,
            _amount,
            block.timestamp
        );
    }

    /**
     * @notice purchase
     */
    function purchase(
        uint256 _collectionId,
        address _user,
        bytes32[] calldata _seeds,
        uint256 _deadline
    ) external onlyOperator {
        // check dead line
        require(_deadline > block.timestamp, "deadline");

        // check collection status
        Collection storage _collection = _collections[_collectionId];

        // check request
        Request storage _request = _requests[_user][_collectionId];
        require(_request.price == _collection.price, "price");
        require(
            _request.tokenAddress == _collection.tokenAddress,
            "token address"
        );
        require(block.number > _request.revealBlock, "reveal");
        require(_request.isPending, "pending");
        require(_request.hashedSeed == keccak256(abi.encodePacked(_seeds)), "hash");

        uint256 returnAmount;
        if (_collection.tokenIds.length < _request.amount){
            returnAmount = _request.amount - _collection.tokenIds.length;
            _request.amount = _collection.tokenIds.length;
        }

        // random NFTs and send to user
        uint256[] memory _tokenIds = new uint256[](_request.amount);
        for (uint256 i = 0; i < _request.amount; i++) {
            // random pick
            nonce++;
            uint256 _pickIndex = _random(
                _collection.tokenIds.length,
                nonce,
                _seeds[i],
                _request.revealBlock
            );
            uint256 _tokenId = _collection.tokenIds[_pickIndex];
            _removeItemByIndex(_collection.tokenIds, _pickIndex);

            // transfer
            IKAP721(_collection.nftAddress).transferFrom(
                address(this),
                _user,
                _tokenId
            );

            _tokenIds[i] = _tokenId;
        }

        //refund remain token to user
        if (returnAmount > 0) {
            _transferToken(treasuryAddress, _user, _collection.tokenAddress, _collection.price * returnAmount);
        }

        _request.isPending = false;

        emit Purchase(
            _user,
            _collectionId,
            _request.hashedSeed,
            _collection.nftAddress,
            _tokenIds,
            _collection.tokenIds.length,
            _request.tokenAddress,
            _collection.price,
            block.timestamp
        );
    }

    /**
     * @notice get remaining nft of a collection
     */
    function getRemainingNft(
        uint256 _collectionId
    ) external view returns (uint256) {
        return _collections[_collectionId].tokenIds.length;
    }

    /**
     * @notice random
     */
    function _random(
        uint256 _length,
        uint256 _nonce,
        bytes32 _randSeed,
        uint256 revealBlock
    ) internal view returns (uint256) {
        return
            uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(revealBlock),
                    _nonce,
                    _randSeed
                )
            )
        ) % _length;
    }

    /**
     * @notice remove item by index
     */
    function _removeItemByIndex(
        uint256[] storage _array,
        uint256 _index
    ) internal {
        require(_index < _array.length);
        if (_index != _array.length - 1) {
            _array[_index] = _array[_array.length - 1];
        }
        delete _array[_array.length - 1];
        _array.pop();
    }

}
