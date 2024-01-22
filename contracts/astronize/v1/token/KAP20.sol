// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IKAP20.sol";
import "../abstracts/KYCHandler.sol";
import "../abstracts/Pauseable.sol";
import "../abstracts/Authorization.sol";
import "../abstracts/Blacklist.sol";


contract KAP20 is IKAP20, KYCHandler, Pauseable, Authorization, Blacklist {
    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) public override allowances;

    uint256 public override totalSupply;

    string public override name;
    string public override symbol;
    uint8 public override decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _admin,
        address _committee,
        IKYCBitkubChain _kyc,
        uint256 _acceptedKycLevel
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        kyc = _kyc;
        acceptedKycLevel = _acceptedKycLevel;
        admin = _admin;
        committee = _committee;
    }

    /**
     * @dev See {IKAP20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IKAP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        notInBlacklist(msg.sender)
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IKAP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        notInBlacklist(msg.sender)
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override whenNotPaused notInBlacklist(sender) notInBlacklist(recipient) returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowances[sender][msg.sender];
        require(currentAllowance >= amount, "KAP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "KAP20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "KAP20: transfer from the zero address");
        require(recipient != address(0), "KAP20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "KAP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "KAP20: mint to the zero address");

        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "KAP20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "KAP20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "KAP20: approve from the zero address");
        require(spender != address(0), "KAP20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function adminTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) public override onlyCommittee returns (bool) {
        require(_balances[sender] >= amount, "KAP20: transfer amount exceed balance");
        require(recipient != address(0), "KAP20: transfer to zero address");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);

        return true;
    }

    function pause() public onlyCommittee {
        _pause();
    }

    function unpause() public onlyCommittee {
        _unpause();
    }

    function addBlacklist(address account) public onlyCommittee {
        _addBlacklist(account);
    }

    function revokeBlacklist(address account) public onlyCommittee {
        _revokeBlacklist(account);
    }

    function activateOnlyKycAddress() public onlyCommittee {
        _activateOnlyKycAddress();
    }

    function setKYC(IKYCBitkubChain _kyc) public onlyCommittee {
        _setKYC(_kyc);
    }

    function setAcceptedKycLevel(uint256 _kycLevel) public onlyCommittee {
        _setAcceptedKycLevel(_kycLevel);
    }
}
