// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "test/TestHelper.t.sol";

/** @dev Trace: -vvvv, No trace: -vv
 * forge test --match-contract Transfer -vv
 */

contract Transfer is TestHelper {
    // alice config: 300-t, 7-all,  1-app,   7-dec
    // bob   config: 500-t, 30-all, 180-app, 30-dec

    /**
     * @dev should send transfer
     */
    function testSpend() public {
        setupUsers();
        vm.startPrank(alice);
        wToken.transfer(cobra, spends[1]);

        assertEq(wToken.balanceOf(alice), initBal - spends[1]);
        assertEq(wToken.balanceOf(cobra), spends[1]);
    }

    /**
     * @dev should send transfer max
     */
    function testSpendMax() public {
        setupUsers();
        vm.startPrank(alice);
        wToken.transfer(cobra, spends[3]);

        assertEq(wToken.balanceOf(alice), initBal - spends[3]);
        assertEq(wToken.balanceOf(cobra), spends[3]);
    }

    /**
     * @dev should fail send transfer: insufficient allowance
     */
    function testSpendAllowanceFail() public {
        setupUsers();
        vm.startPrank(alice);
        vm.expectRevert("SL: cannot breach spending limit");
        wToken.transfer(cobra, spends[4]);

        assertEq(wToken.balanceOf(alice), initBal);
        assertEq(wToken.balanceOf(cobra), spends[0]);
    }

    /**
     * @dev should fail send transfer: insufficient balance
     */
    function testSpendBalanceFail() public {
        setupUsers();
        vm.startPrank(alice);
        wToken.withdrawTo(alice, spends[9]);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        wToken.transfer(cobra, spends[2]);

        assertEq(wToken.balanceOf(alice), initBal - spends[9]);
        assertEq(wToken.balanceOf(cobra), spends[0]);
    }

    /**
     * @dev should fail multi send transfer: insufficient allowance
     */
    function testMultiSpendFail() public {
        setupUsers();
        vm.startPrank(alice);
        wToken.transfer(cobra, spends[1]);
        (uint256 limit, uint256 spent1) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit, spends[3]);
        assertEq(spent1, spends[1]);

        wToken.transfer(cobra, spends[1]);
        (, uint256 spent2) = wToken.getAllowanceLimitAndSpent();
        assertEq(spent2, spends[2]);

        wToken.transfer(cobra, spends[1]);
        (, uint256 spent3) = wToken.getAllowanceLimitAndSpent();
        assertEq(spent3, spends[3]);

        vm.expectRevert("SL: cannot breach spending limit");
        wToken.transfer(cobra, spends[1]);

        assertEq(wToken.balanceOf(alice), initBal - spends[3]);
        assertEq(wToken.balanceOf(cobra), spends[3]);
    }

    /**
     * @dev should send transfer, recieve transfer, fail send transfer
     */
    function testSendAndRecieve() public {
        setupUsers();
        vm.startPrank(alice);
        wToken.transfer(cobra, spends[3]);
        vm.stopPrank();

        vm.startPrank(bob);
        wToken.transfer(alice, spends[5]);
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert("SL: cannot breach spending limit");
        wToken.transfer(cobra, spends[1]);

        assertEq(wToken.balanceOf(alice), initBal + spends[2]);
        assertEq(wToken.balanceOf(bob), initBal - spends[5]);
    }

    /**
     * @dev should send transfer, increase limit, send transfer
     * although spending limit increased, it will not take effect until next period
     */
    function testSendAndIncreaseLimit() public {
        setupUsers();
        vm.startPrank(alice);
        wToken.transfer(cobra, spends[3]);

        (uint256 limit1, uint256 spent1) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit1, spends[3]);
        assertEq(spent1, spends[3]);

        wToken.setCustomConfig(
            spends[5],
            all_period[0],
            app_period[0],
            decay_int[0]
        );

        (uint256 limit2, uint256 spent2) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit2, spends[5]);
        assertEq(spent2, spends[3]);

        vm.expectRevert("SL: cannot breach spending limit");
        wToken.transfer(cobra, spends[5]);

        wToken.transfer(cobra, spends[2]);

        (uint256 limit3, uint256 spent3) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit3, spends[5]);
        assertEq(spent3, spends[5]);

        vm.warp(block.timestamp + 8 days);
        (uint256 limit, uint256 spent) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit, spends[5]);
        assertEq(spent, spends[0]);

        wToken.transfer(cobra, spends[5]);

        assertEq(wToken.balanceOf(alice), spends[0]);
        assertEq(wToken.balanceOf(cobra), spends[0] + initBal);
    }

    /**
     * @dev should send transfer, decrease limit, send transfer
     */
    function testSendAndDecreaseLimit() public {
        setupUsers();
        vm.startPrank(bob);
        wToken.transfer(cobra, spends[5]);

        (uint256 limit1, uint256 spent1) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit1, spends[5]);
        assertEq(spent1, spends[5]);

        wToken.setCustomConfig(
            spends[3],
            all_period[1],
            app_period[1],
            decay_int[1]
        );

        vm.expectRevert("SL: cannot breach spending limit");
        wToken.transfer(cobra, spends[1]);

        (uint256 limit2, uint256 spent2) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit2, spends[3]);
        assertEq(spent2, spends[5]);

        vm.warp(block.timestamp + 31 days);
        (uint256 limit3, uint256 spent3) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit3, spends[3]);
        assertEq(spent3, spends[0]);

        wToken.transfer(cobra, spends[3]);

        assertEq(wToken.balanceOf(bob), initBal - spends[8]);
        assertEq(wToken.balanceOf(cobra), spends[8]);
    }

    /**
     * @dev should send transfer, increase limit, send transfer over time
     */
    function testSendAndIncreaseLimitOverTime() public {
        setupUsers();
        vm.warp(block.timestamp + 1 days);
        assertEq(block.timestamp, 1 days + 1 seconds);

        vm.startPrank(alice);
        wToken.transfer(cobra, spends[3]);

        (uint256 limit1, uint256 spent1) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit1, spends[3]);
        assertEq(spent1, spends[3]);

        vm.warp(block.timestamp + 1 days);
        assertEq(block.timestamp, 2 days + 1 seconds);

        wToken.setCustomConfig(
            spends[5],
            all_period[0],
            app_period[0],
            decay_int[0]
        );

        vm.warp(block.timestamp + 1 days);
        assertEq(block.timestamp, 3 days + 1 seconds);

        (uint256 limit2, uint256 spent2) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit2, spends[5]);
        assertEq(spent2, spends[3]);

        vm.expectRevert("SL: cannot breach spending limit");
        wToken.transfer(cobra, spends[5]);

        vm.warp(block.timestamp + 1 days);
        assertEq(block.timestamp, 4 days + 1 seconds);

        wToken.transfer(cobra, spends[2]);

        (uint256 limit3, uint256 spent3) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit3, spends[5]);
        assertEq(spent3, spends[5]);

        vm.warp(block.timestamp + 4 days);
        assertEq(block.timestamp, 8 days + 1 seconds);

        (uint256 limit4, uint256 spent4) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit4, spends[5]);
        assertEq(spent4, spends[0]);

        wToken.transfer(cobra, spends[5]);

        assertEq(wToken.balanceOf(alice), spends[0]);
        assertEq(wToken.balanceOf(cobra), spends[0] + initBal);
    }

    /**
     * @dev allowance should reset at the end time
     */
    function testAllowanceReset() public {
        setupUsers();
        vm.startPrank(alice);

        vm.warp(block.timestamp + 2 days);
        assertEq(block.timestamp, 2 days + 1 seconds);

        (uint256 start1, uint256 end1) = wToken.getAllowanceStartAndEnd();
        assertEq(start1, 1 seconds);
        assertEq(end1, 7 days + 1 seconds);

        (uint256 limit1, uint256 spent1) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit1, spends[3]);
        assertEq(spent1, spends[0]);

        vm.warp(block.timestamp + 2 days);
        assertEq(block.timestamp, 4 days + 1 seconds);

        wToken.transfer(cobra, spends[1]);

        (uint256 limit2, uint256 spent2) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit2, spends[3]);
        assertEq(spent2, spends[1]);

        vm.warp(block.timestamp + 2 days);
        assertEq(block.timestamp, 6 days + 1 seconds);

        wToken.transfer(cobra, spends[2]);

        (uint256 limit3, uint256 spent3) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit3, spends[3]);
        assertEq(spent3, spends[3]);

        vm.warp(block.timestamp + 2 days);
        assertEq(block.timestamp, 8 days + 1 seconds);

        (uint256 start2, uint256 end2) = wToken.getAllowanceStartAndEnd();
        assertEq(start2, 7 days + 1 seconds);
        assertEq(end2, 14 days + 1 seconds);

        (uint256 limit4, uint256 spent4) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit4, spends[3]);
        assertEq(spent4, spends[0]);
    }

    // todo update config settings

    // todo spend allowance, update config to more, over-spend
    // todo spend allowance, update config to less, spend to new limit
    // todo spend allowance, update config to less, over-spend
    // todo spend allowance after renew
    // todo transfer, approve/transFrom spend combination
    // todo transfer, approve/transFrom over-spend combination

    // todo approve, update config, attempt to breach current limit with old approval
}
