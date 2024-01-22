// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./library/BokkyPooBahsDateTimeLibrary.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AstronizeVesting is AccessControl {
    using BokkyPooBahsDateTimeLibrary for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event Claim(
        address indexed sender,
        uint256 indexed month,
        uint256 indexed year,
        uint256 timestamp
    );
    event WalletsAdded(address indexed sender, address[] wallets);
    event WalletsRemoved(address indexed sender, address[] wallets);

    // mapping year => month => is claimed
    mapping(uint256 => mapping(uint256 => bool)) internal _claims;
    EnumerableSet.AddressSet internal _wallets;
    IERC20 public token;
    uint256 public transferAmount;
    uint256 public startAt;
    uint256[] public claimableMonths;
    uint256 public desiredNumWallets;
    uint256 public firstTransferAmount;
    bool public isFirstTransfer;

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
     * @notice claim token
     */
    function claim(uint256 month, uint256 year) external {
        require(desiredNumWallets == walletLength(), "invalid num wallets");

        // check month
        require(inArray(claimableMonths, month), "invalid month");

        // check time
        uint256 claimTime = getTimestampForMonthAndYear(month, year);
        require(block.timestamp >= claimTime, "not yet time");
        require(claimTime >= startAt, "start at");

        // check claim
        require(!_claims[month][year], "already claimed");
        _claims[month][year] = true;

        // transfer token
        _transferToken();

        // emit event
        emit Claim(msg.sender, month, year, block.timestamp);
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
    function _transferToken() internal {
        uint256 _transferAmount;

        // check is first transfer
        if (!isFirstTransfer) {
            isFirstTransfer = true;
            _transferAmount = firstTransferAmount;
        }

        // check transfer amount
        if (_transferAmount == 0) {
            _transferAmount = transferAmount;
        }

        // transfer
        uint256 numUsers = _wallets.length();
        for (uint256 i = 0; i < numUsers; i++) {
            address user = _wallets.at(i);
            token.transfer(user, _transferAmount);
        }
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
    function wallets() public view returns (address[] memory) {
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
}
