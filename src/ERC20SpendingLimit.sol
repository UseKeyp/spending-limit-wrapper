// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20Wrapper} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ERC20SpendingLimit is ERC20Wrapper {
    mapping(address => UserConfig) internal _configs;

    /** @dev UserConfig
     * all transfers call `_checkAndUpdateAllowancePeriod`
     * which checks that UserConfig exists
     * owner of tokens must create config before outbound transfers are enabled
     *
     * spent = sum of `_transfer` during `allowancePeriod`
     * spendingLimit = spending limit during `allowancePeriod`
     * allowanceStart = allowance start-time, set with `spendingLimit`
     * allowancePeriod = allowance period before `spent` is reset
     * approvalPeriod = allowance period for token approvals before expiration
     * decayInterval = decay rate half-life of token approvals
     * approvalStart = allowance expiration of token approvals
     */
    struct UserConfig {
        uint256 spent;
        uint256 spendingLimit;
        uint256 allowanceStart;
        uint256 allowancePeriod;
        uint256 approvalPeriod;
        uint256 decayInterval;
        mapping(address => uint256) approvalStart;
    }

    constructor(
        string memory name,
        string memory symbol,
        IERC20 underlyingToken
    ) ERC20(name, symbol) ERC20Wrapper(underlyingToken) {}

    /**
     * @dev see {ERC20 approve}
     * UserConfig spender approval start-time updated
     */
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        address owner = _msgSender();
        require(
            amount <= _configs[owner].spendingLimit,
            "SL: approval exceeds spending limit"
        );
        _approve(owner, spender, amount);
        _configs[owner].approvalStart[spender] = block.timestamp;
        return true;
    }

    /**
     * @dev set custom config
     * for infinite input, set to max int (2**256 - 1)
     * if new config, set `allowanceStart` to `block.timestamp`
     * otherwise update based on `_allowancePeriod`
     */
    function setCustomConfig(
        uint256 _spendingLimit,
        uint256 _allowancePeriod,
        uint256 _approvalPeriod,
        uint256 _decayInterval
    ) public {
        uint256 timestamp = block.timestamp;
        UserConfig storage config = _configs[msg.sender];
        uint256 start = config.allowanceStart;

        config.spendingLimit = _spendingLimit;
        config.allowancePeriod = _allowancePeriod;
        config.approvalPeriod = _approvalPeriod;
        config.decayInterval = _decayInterval;

        if (start > 0) {
            if (timestamp > start + _allowancePeriod) {
                uint256 periods = (timestamp - start) / _allowancePeriod;
                config.allowanceStart = start + (periods * _allowancePeriod);
            }
        } else {
            config.allowanceStart = timestamp;
        }
    }

    /**
     * @dev set default config
     * 1000 tokens, 1 month allowance, 6 month approval, 1 month half-life
     */
    function setDefaultConfig() external {
        uint256 spendingLimit = 1000 * 1e18;
        setCustomConfig(spendingLimit, 30 days, 182.5 days, 30 days);
    }

    /**
     * @dev get current allowance period start and end
     */
    function getAllowanceStartAndEnd()
        external
        returns (uint256 start, uint256 end)
    {
        _checkAndUpdateAllowancePeriod(msg.sender);
        start = _configs[msg.sender].allowanceStart;
        end = start + _configs[msg.sender].allowancePeriod;
    }

    /**
     * @dev get current allowance limit and spent
     */
    function getAllowanceLimitAndSpent()
        external
        returns (uint256 spendingLimit, uint256 spent)
    {
        _checkAndUpdateAllowancePeriod(msg.sender);
        spendingLimit = _configs[msg.sender].spendingLimit;
        spent = _configs[msg.sender].spent;
    }

    /**
     * @dev get token approval start time and expiration
     */
    function getApprovalStartAndEnd(
        address spender
    ) external view returns (uint256 approvalStart, uint256 expiration) {
        approvalStart = _configs[msg.sender].approvalStart[spender];
        expiration = approvalStart + _configs[msg.sender].approvalPeriod;
    }

    /**
     * @dev get token approval and decay rates
     */
    function getApprovalPeriodAndDecay()
        external
        view
        returns (uint256 approvalPeriod, uint256 decayInterval)
    {
        approvalPeriod = _configs[msg.sender].approvalPeriod;
        decayInterval = _configs[msg.sender].decayInterval;
    }

    /**
     * @dev see {ERC20 _spendAllowance}
     * enfore approval expiration and decay periods
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        uint256 timestamp = block.timestamp;
        uint256 start = _configs[owner].approvalStart[spender];
        require(
            timestamp < start + _configs[owner].approvalPeriod,
            "SL: approval expired"
        );

        uint256 decayInterval = _configs[owner].decayInterval;
        uint256 currentAllowance = allowance(owner, spender);

        if (timestamp > (start + decayInterval)) {
            uint256 periods = (timestamp - start) / decayInterval;
            uint256 decay = _decay(periods, currentAllowance);
            require(amount <= decay, "SL: amount exceeds decay");
        }
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev enfore spending limit
     * if `from` and `to` are non-zero, token transfer (spend)
     * if `from` is zero, token mint (wrapping)
     * if `to` is zero, token burn (unwrapping)
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0) && to != address(0)) {
            _checkAndUpdateAllowancePeriod(from);

            uint256 toSpend = _configs[from].spent + amount;
            require(
                _configs[from].spendingLimit >= toSpend,
                "SL: cannot breach spending limit"
            );

            _configs[from].spent = toSpend;
        }
    }

    /**
     * @dev check `allowancePeriod` is up-to-date
     * if not, update `allowancePeriod` and set `spent` to zero
     * if `allowanceStart` is zero, `transferFrom` call
     */
    function _checkAndUpdateAllowancePeriod(address owner) internal {
        uint256 allowanceStart = _configs[owner].allowanceStart;
        require(allowanceStart > 0, "SL: config does not exist");
        uint256 allowancePeriod = _configs[owner].allowancePeriod;
        uint256 timestamp = block.timestamp;

        if (timestamp > (allowanceStart + allowancePeriod)) {
            uint256 periods = (timestamp - allowanceStart) / allowancePeriod;

            _configs[owner].allowanceStart =
                allowanceStart +
                (periods * allowancePeriod);

            _configs[owner].spent = 0;
        }
    }

    /**
     * @dev calculate decay rate half-life
     */
    function _decay(uint256 n, uint256 amount) internal returns (uint256) {
        if (n == 0) return amount;
        if (n == 1) return amount / 2;
        else return _decay(n - 1, amount / 2);
    }
}
