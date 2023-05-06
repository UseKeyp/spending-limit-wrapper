// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "test/TestHelper.t.sol";

/** @dev Trace: -vvvv, No trace: -vv
 * forge test --match-contract TransferFrom -vv
 */

contract TransferFrom is TestHelper {
    // alice config: 300-t, 7-all,  1-app,   7-dec
    // bob   config: 500-t, 30-all, 180-app, 30-dec
    // function test
    // todo approve and spend
    // todo approve and over-spend
    // todo over-spend balance, not allowance
    // todo approve and spend after expiration
    // todo approve and spend after decay
    // todo approve and spend after multi decay
    // todo approve and spend after decay, spend after expiration
    // todo approve and spend, recieve funds, spend
    // todo multi approval and multi spend
    // todo multi approval and multi over-spend
    // todo approve/transFrom, transfer spend combination
    // todo approve/transFrom, transfer over-spend combination
}
