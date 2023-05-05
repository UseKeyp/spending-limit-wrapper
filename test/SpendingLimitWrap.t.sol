// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "test/TestHelper.t.sol";

/** @dev Trace: -vvvv, No trace: -vv
 * forge test --match-contract SpendingLimitWrap -vv
 */

contract SpendingLimitWrap is TestHelper {
    /**
     * @dev Should swap from ERC20 to ERC20Wrapped
     * Alice approves wToken to underlying-asset before deposit
     */
    function testDepositSuccess() public {
        deposit(alice, 100);
    }

    /**
     * @dev Should fail swap from ERC20 to ERC20Wrapped
     */
    function testDepositFail() public {
        vm.startPrank(alice);

        token.approve(address(wToken), 100);

        vm.expectRevert("ERC20: insufficient allowance");
        wToken.depositFor(alice, 200);

        assertEq(token.balanceOf(alice), 1000);
        assertEq(wToken.balanceOf(alice), 0);
    }

    /**
     * @dev Should withdraw partial
     */
    function testWithdrawSuccess() public {
        deposit(alice, 100);

        vm.startPrank(alice);
        wToken.withdrawTo(alice, 80);

        assertEq(token.balanceOf(alice), 980);
        assertEq(wToken.balanceOf(alice), 20);
    }

    /**
     * @dev Should withdraw max
     */
    function testWithdrawSuccessMax() public {
        deposit(alice, 100);

        vm.startPrank(alice);
        wToken.withdrawTo(alice, 100);

        assertEq(token.balanceOf(alice), 1000);
        assertEq(wToken.balanceOf(alice), 0);
    }

    /**
     * @dev Should fail withdraw, deposit intact
     */
    function testWithdrawFail() public {
        deposit(alice, 100);

        vm.startPrank(alice);
        vm.expectRevert("ERC20: burn amount exceeds balance");
        wToken.withdrawTo(alice, 200);

        assertEq(token.balanceOf(alice), 900);
        assertEq(wToken.balanceOf(alice), 100);
    }
}
