// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./library/BokkyPooBahsDateTimeLibrary.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AstronizeVesting is AccessControl {
    using SafeERC20 for IERC20;
    using BokkyPooBahsDateTimeLibrary for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event Claim(
        address indexed user,
        uint256 indexed month,
        uint256 indexed year,
        address sender,
        uint256 timestamp
    );
    event WalletsAdded(address indexed sender, address[] wallets);
    event WalletsRemoved(address indexed sender, address[] wallets);

    // mapping year => month => is claimed
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) internal _claims;
    mapping(uint256 => mapping(uint256 => uint256)) internal _claimCounts;
    mapping(address => bool) public isFirstTransfers;
    EnumerableSet.AddressSet internal _wallets;
    IERC20 public token;
    uint256 public transferAmount;
    uint256 public startAt;
    uint256[] public claimableMonths;
    uint256 public desiredNumWallets;
    uint256 public firstTransferAmount;

    constructor(
        address _tokenAddress,
        uint256 _desiredNumWallets,
        uint256 _startMonth,
        uint256 _startYear,
        uint256[] memory _claimableMonths,
        uint256 _transferAmount,
        uint256 _firstTransferAmount
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        token = IERC20(_tokenAddress);
        desiredNumWallets = _desiredNumWallets;
        startAt = getTimestampForMonthAndYear(_startMonth, _startYear);
        transferAmount = _transferAmount;
        firstTransferAmount = _firstTransferAmount;

        // validate months and start at
        for (uint i = 0; i < _claimableMonths.length; i++) {
            require(
                _claimableMonths[i] >= 1 && _claimableMonths[i] <= 12,
                "invalid month"
            );
        }
        claimableMonths = _claimableMonths;
    }

    /**
     * @notice get claim
     */
    function claimOf(uint256 month,uint256 year,address user) external view returns (bool) {
        return _claims[month][year][user];
    }

    /**
     * @notice get claim count
     */
    function claimCountOf(uint256 month,uint256 year) external view returns (uint256) {
        return _claimCounts[month][year];
    }

    /**
     * @notice batch claim
     */
    function batchClaim(address[] calldata users,uint256 month, uint256 year) external {
        for (uint256 i = 0;i<users.length;i++) {
            claim(users[i], month, year);
        }
    }

    /**
     * @notice claim token
     */
    function claim(address user,uint256 month, uint256 year) public {
        // check claim count
        require(_claimCounts[month][year]<desiredNumWallets,"claim count");
        _claimCounts[month][year]++;

        // check month
        require(inArray(claimableMonths, month), "invalid month");

        // check time
        uint256 claimTime = getTimestampForMonthAndYear(month, year);
        require(block.timestamp >= claimTime, "not yet time");
        require(claimTime >= startAt, "start at");

        // check claim
        require(!_claims[month][year][user], "already claimed");
        _claims[month][year][user] = true;

        // transfer token
        require(_wallets.contains(user),"wallet not on the list");
        _transferToken(user);

        // emit event
        emit Claim(user, month, year,msg.sender, block.timestamp);
    }

    /**
     * @notice get unix timestamp from month and year
     */
    function getTimestampForMonthAndYear(
        uint256 month,
        uint256 year
    ) public pure returns (uint256) {
        require(month >= 1 && month <= 12, "invalid month");
        require(year >= 1970 && year <= 2105, "invalid year");
        return BokkyPooBahsDateTimeLibrary.timestampFromDate(year, month, 1);
    }

    /**
     * @notice in array
     */
    function inArray(
        uint256[] memory array,
        uint256 target
    ) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == target) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice transfer token to wallets
     */
    function _transferToken(address user) internal {
        uint256 _transferAmount;

        // check is first transfer
        if (!isFirstTransfers[user]) {
            isFirstTransfers[user] = true;
            _transferAmount = firstTransferAmount;
        }

        // check transfer amount
        if (_transferAmount == 0) {
            _transferAmount = transferAmount;
        }

        token.safeTransfer(user, _transferAmount);
    }

    /**
     * @notice add wallets
     */
    function addWallets(
        address[] calldata _walletsToAdd
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _wallets.length() + _walletsToAdd.length <= desiredNumWallets,
            "exceeded num wallets"
        );

        for (uint256 i = 0; i < _walletsToAdd.length; i++) {
            require(
                !_wallets.contains(_walletsToAdd[i]),
                "wallet already exists"
            );
            _wallets.add(_walletsToAdd[i]);
        }

        emit WalletsAdded(msg.sender, _walletsToAdd);
    }

    /**
     * @notice remove wallets
     */
    function removeWallets(
        address[] calldata _walletsToRemove
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _walletsToRemove.length; i++) {
            require(_wallets.contains(_walletsToRemove[i]), "wallet not found");
            _wallets.remove(_walletsToRemove[i]);
        }

        emit WalletsRemoved(msg.sender, _walletsToRemove);
    }

    /**
     * @notice list wallet
     */
    function wallets() external view returns (address[] memory) {
        address[] memory walletList = new address[](_wallets.length());
        for (uint256 i = 0; i < _wallets.length(); i++) {
            address user = _wallets.at(i);
            walletList[i] = user;
        }

        return walletList;
    }

    /**
     * @notice wallet length
     */
    function walletLength() public view returns (uint256) {
        return _wallets.length();
    }

    /**
     * @notice claimable month list
     */
    function claimableMonthList() external view returns (uint256[] memory) {
        return claimableMonths;
    }
}