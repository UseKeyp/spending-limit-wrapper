// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "test/TestHelper.t.sol";

/** @dev Trace: -vvvv, No trace: -vv
 * forge test --match-contract TransferFrom -vv
 */

contract TransferFrom is TestHelper {
    // alice config: 300-t, 7-all,  30-app,   7-dec
    // bob   config: 500-t, 30-all, 180-app, 30-dec

    /**
     * @dev should approve and send transferFrom
     */
    function testSpend() public {
        setupUsers();
        vm.startPrank(alice);
        wToken.approve(cobra, spends[1]);
        vm.stopPrank();

        vm.startPrank(cobra);
        wToken.transferFrom(alice, bob, spends[1]);
        assertEq(wToken.balanceOf(alice), initBal - spends[1]);
        assertEq(wToken.balanceOf(bob), initBal + spends[1]);
    }

    /**
     * @dev should fail approval over spend limit
     */
    function testApproveFail() public {
        setupUsers();
        vm.startPrank(alice);
        vm.expectRevert("SL: approval exceeds spending limit");
        wToken.approve(cobra, spends[9]);
        vm.stopPrank();
    }

    /**
     * @dev should fail spend over approval
     */
    function testSpendFail() public {
        setupUsers();
        vm.startPrank(alice);
        wToken.approve(cobra, spends[1]);
        vm.stopPrank();

        vm.startPrank(cobra);
        vm.expectRevert("ERC20: insufficient allowance");
        wToken.transferFrom(alice, bob, spends[2]);
    }

    /**
     * @dev should fail spend after expiration
     */
    function testApprovalExpiration() public {
        setupUsers();
        vm.startPrank(alice);
        wToken.approve(cobra, spends[3]);

        (uint256 expiration, uint256 decay) = wToken
            .getApprovalPeriodAndDecay();
        assertEq(expiration, 30 days);
        assertEq(decay, 7 days);
        vm.stopPrank();

        vm.startPrank(cobra);
        wToken.transferFrom(alice, bob, spends[1]);

        warpForward(31 days, 31 days);
        vm.expectRevert("SL: approval expired");
        wToken.transferFrom(alice, bob, spends[1]);
    }

    /**
     * @dev should spend max before decay begins
     */
    function testApprovalDecay() public {
        setupUsers();
        vm.startPrank(alice);
        wToken.approve(cobra, spends[3]);
        vm.stopPrank();

        warpForward(7 days, 7 days);

        vm.startPrank(cobra);
        wToken.transferFrom(alice, bob, spends[3]);
        assertEq(wToken.balanceOf(alice), initBal - spends[3]);
        assertEq(wToken.balanceOf(bob), initBal + spends[3]);
    }

    /**
     * @dev should fail spend original approved amount
     * should spend decayed amount
     */
    function testApprovalDecayFail() public {
        setupUsers();
        vm.startPrank(alice);
        wToken.approve(cobra, spends[3]);
        vm.stopPrank();

        warpForward(9 days, 9 days);

        vm.startPrank(cobra);
        vm.expectRevert("SL: amount exceeds decay");
        wToken.transferFrom(alice, bob, spends[3]);

        wToken.transferFrom(alice, bob, spends[1]);
        assertEq(wToken.balanceOf(alice), initBal - spends[1]);
    }

    /**
     * @dev should multi fail spend original approved amount
     * should spend multi decayed amount
     */
    function testApprovalMultiDecayFail() public {
        setupUsers();
        vm.startPrank(bob);
        warpForward(1 days, 1 days);
        wToken.approve(cobra, spends[5]);

        (uint256 cobraStart, uint256 cobraEnd) = wToken.getApprovalStartAndEnd(
            cobra
        );
        assertEq(cobraStart, 1 days + 1 seconds);
        assertEq(cobraEnd, 181 days + 1 seconds);

        (uint256 expiration, uint256 decay) = wToken
            .getApprovalPeriodAndDecay();
        assertEq(expiration, 180 days);
        assertEq(decay, 30 days);
        vm.stopPrank();

        warpForward(60 days, 61 days);

        assertTrue(block.timestamp < (cobraStart + expiration));

        vm.startPrank(cobra);
        vm.expectRevert("SL: amount exceeds decay");
        wToken.transferFrom(bob, alice, spends[5]);

        vm.expectRevert("SL: amount exceeds decay");
        wToken.transferFrom(bob, alice, spends[4]);

        vm.expectRevert("SL: amount exceeds decay");
        wToken.transferFrom(bob, alice, spends[3]);

        vm.expectRevert("SL: amount exceeds decay");
        wToken.transferFrom(bob, alice, spends[2]);

        wToken.transferFrom(bob, alice, spends[1]);
        assertEq(wToken.balanceOf(bob), initBal - spends[1]);
    }

    /**
     * @dev should fail spend original approved amount
     */
    function testApprovalMultiDecayFail2() public {
        setupUsers();
        vm.startPrank(alice);
        warpForward(1 days, 1 days);
        wToken.approve(cobra, spends[3]);

        (uint256 expiration, uint256 decay) = wToken
            .getApprovalPeriodAndDecay();
        assertEq(expiration, 30 days);
        assertEq(decay, 7 days);
        vm.stopPrank();

        warpForward(8 days, 9 days);

        vm.startPrank(cobra);
        vm.expectRevert("SL: amount exceeds decay");
        wToken.transferFrom(alice, bob, spends[3]);

        vm.expectRevert("SL: amount exceeds decay");
        wToken.transferFrom(alice, bob, spends[2]);

        wToken.transferFrom(alice, bob, spends[1]);

        warpForward(22 days, 31 days);

        vm.expectRevert("SL: approval expired");
        wToken.transferFrom(alice, bob, spends[1]);
    }

    /**
     * @dev should approve and send transferFrom
     */
    function testMultiSpend() public {
        setupUsers();
        vm.startPrank(bob);
        wToken.approve(alice, spends[5]);
        wToken.approve(cobra, spends[5]);
        vm.stopPrank();

        vm.startPrank(alice);
        wToken.transferFrom(bob, alice, spends[4]);
        vm.stopPrank();

        vm.startPrank(cobra);
        vm.expectRevert("SL: cannot breach spending limit");
        wToken.transferFrom(bob, cobra, spends[2]);
        vm.stopPrank();

        vm.startPrank(cobra);
        wToken.transferFrom(bob, cobra, spends[1]);
        vm.stopPrank();

        assertEq(wToken.balanceOf(bob), initBal - spends[5]);
        assertEq(wToken.balanceOf(alice), initBal + spends[4]);
        assertEq(wToken.balanceOf(cobra), spends[0] + spends[1]);
    }

    /**
     * @dev should approve and send transferFrom
     * should maintain individual approval times
     * should enforce decay and expiration limits
     */
    function testMultiSpendDecayFail() public {
        setupUsers();
        vm.startPrank(alice);
        wToken.approve(bob, spends[3]);
        warpForward(8 days, 8 days);
        wToken.approve(cobra, spends[3]);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert("SL: amount exceeds decay");
        wToken.transferFrom(alice, cobra, spends[3]);
        wToken.transferFrom(alice, cobra, spends[1]);
        vm.stopPrank();

        vm.startPrank(cobra);
        wToken.transferFrom(alice, bob, spends[2]);
        vm.stopPrank();

        assertEq(wToken.balanceOf(alice), initBal - spends[3]);
        assertEq(wToken.balanceOf(bob), initBal + spends[2]);
        assertEq(wToken.balanceOf(cobra), spends[0] + spends[1]);
    }

    /**
     * @dev should approve, decrease config approval
     * should attempt to breach new approval and fail transferFrom
     */
    function testApprovalUpdateBreachFail() public {
        setupUsers();
        vm.startPrank(bob);
        wToken.approve(cobra, spends[5]);
        wToken.setCustomConfig(
            spends[3],
            all_period[1],
            app_period[1],
            decay_int[1]
        );
        vm.stopPrank();

        vm.startPrank(cobra);
        vm.expectRevert("SL: cannot breach spending limit");
        wToken.transferFrom(bob, alice, spends[5]);
        wToken.transferFrom(bob, alice, spends[3]);

        assertEq(wToken.balanceOf(bob), initBal - spends[3]);
        assertEq(wToken.balanceOf(alice), initBal + spends[3]);
    }
}
