// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20Wrapper} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract SpendingLimitERC20 is ERC20Wrapper {
    mapping(address => OwnerConfig) internal _configs;

    struct OwnerConfig {
        uint256 allowanceStart;
        uint256 allowancePeriod;
        uint256 spendingLimit;
        uint256 approvalPeriod;
        uint256 decayInterval;
        uint256 spent;
        mapping(address => uint256) approvalStarts;
    }

    constructor(
        string memory name,
        string memory symbol,
        IERC20 underlyingToken
    ) ERC20(name, symbol) ERC20Wrapper(underlyingToken) {}

    /**
     * @dev see {ERC20 approve}
     * OwnerConfig spender approval start-time updated
     */
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        _configs[msg.sender].approvalStarts[spender] = block.timestamp;
        return true;
    }

    /**
     * @dev set default config
     */
    function setDefaultConfig() external {
        setSpendingLimit(1000 * (1e18)); // 1000 tokens
        setDecayInterval(30 days); // 1 month halving
        setExpiration(182.5 days); // 6 month expiration
    }

    /**
     * @dev set spending limit for allowance period
     * set to max int (2**256 - 1) for no limit
     */
    function setSpendingLimit(uint256 _spendingLimit) public {
        _configs[msg.sender].spendingLimit = _spendingLimit;
    }

    /**
     * @dev set approval half-life interval (e.g. 1 months)
     * approval amount halves at each interval until expiration
     * set to max int (2**256 - 1) for no decay
     */
    function setDecayInterval(uint256 _decayInterval) public {
        _configs[msg.sender].decayInterval = _decayInterval;
    }

    /**
     * @dev set approval period before expiration (e.g. 6 months)
     * approval amount zeroed / revoked when active period ends
     * set to max int (2**256 - 1) for no expiration
     */
    function setExpiration(uint256 _approvalPeriod) public {
        _configs[msg.sender].approvalPeriod = _approvalPeriod;
    }

    /**
     * @dev get spending limit for allowance period
     */
    function getSpendingLimit() external view returns (uint256) {
        return _configs[msg.sender].spendingLimit;
    }

    /**
     * @dev get approval half-life interval (e.g. 1 months)
     */
    function getDecayInterval() external view returns (uint256) {
        return _configs[msg.sender].decayInterval;
    }

    /**
     * @dev get approval expiration (e.g. 6 months)
     */
    function getExpiration() external view returns (uint256) {
        return _configs[msg.sender].approvalPeriod;
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
        uint256 approvalStart = _configs[msg.sender].approvalStarts[spender];
        uint256 approvalPeriod = _configs[msg.sender].approvalPeriod;
        uint256 timestamp = block.timestamp;

        require(
            timestamp <= (approvalStart + approvalPeriod),
            "SL: approval expired"
        );

        uint256 currentAllowance = allowance(owner, spender);

        if (currentAllowance != type(uint256).max) {
            uint256 period = timestamp - approvalStart;

            if (period > approvalPeriod) {
                uint256 periods = period / _configs[msg.sender].decayInterval;
                currentAllowance = _decay(periods, currentAllowance);
            }

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
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // if `from` and `to` are non-zero, token transfer (spend)
        // if `from` is zero, token mint (wrapping)
        // if `to` is zero, token burn (unwrapping)
        if (from != address(0) && to != address(0)) {
            uint256 allowanceStart = _configs[msg.sender].allowanceStart;
            uint256 allowancePeriod = _configs[msg.sender].allowancePeriod;
            uint256 timestamp = block.timestamp;

            // check allowance period
            if (timestamp > (allowanceStart + allowancePeriod)) {
                // calculate new start period
                uint256 periods = (timestamp - allowanceStart) /
                    allowancePeriod;

                // set current allowance period
                _configs[msg.sender].allowanceStart =
                    allowanceStart +
                    (periods * allowancePeriod);

                // reset allowance
                _configs[msg.sender].spent = 0;
            }

            // check allowance
            uint256 toSpend = _configs[msg.sender].spent + amount;
            require(
                _configs[msg.sender].spendingLimit >= toSpend,
                "SL: cannot breach spending limit"
            );

            // update spent
            _configs[msg.sender].spent = toSpend;
        }
    }

    /**
     * @dev calculate decay
     */
    function _decay(uint256 n, uint256 amount) internal returns (uint256) {
        if (n == 0) return amount;
        if (n == 1) return amount / 2;
        else return _decay(n - 1, amount / 2);
    }
}
