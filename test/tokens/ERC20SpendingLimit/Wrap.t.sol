// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "test/TestHelper.t.sol";

/** @dev Trace: -vvvv, No trace: -vv
 * forge test --match-contract Wrap -vv
 */

contract Wrap is TestHelper {
    /**
     * @dev should swap from ERC20 to ERC20Wrapped
     * alice approves wToken to underlying-asset before deposit
     */
    function testDepositSuccess() public {
        deposit(alice, depositAmt);
    }

    /**
     * @dev should fail swap from ERC20 to ERC20Wrapped
     */
    function testDepositFail() public {
        vm.startPrank(alice);

        token.approve(address(wToken), depositAmt);

        vm.expectRevert("ERC20: insufficient allowance");
        wToken.depositFor(alice, withdraw[1]);

        assertEq(token.balanceOf(alice), initBal);
        assertEq(wToken.balanceOf(alice), spends[0]);
    }

    /**
     * @dev should withdraw partial
     */
    function testWithdrawSuccess() public {
        deposit(alice, depositAmt);

        vm.startPrank(alice);
        wToken.withdrawTo(alice, withdraw[0]);

        assertEq(token.balanceOf(alice), initBal - depositAmt + withdraw[0]);
        assertEq(wToken.balanceOf(alice), depositAmt - withdraw[0]);
    }

    /**
     * @dev should withdraw max
     */
    function testWithdrawSuccessMax() public {
        deposit(alice, depositAmt);

        vm.startPrank(alice);
        wToken.withdrawTo(alice, depositAmt);

        assertEq(token.balanceOf(alice), initBal);
        assertEq(wToken.balanceOf(alice), spends[0]);
    }

    /**
     * @dev should fail withdraw, deposit intact
     */
    function testWithdrawFail() public {
        deposit(alice, depositAmt);

        vm.startPrank(alice);
        vm.expectRevert("ERC20: burn amount exceeds balance");
        wToken.withdrawTo(alice, withdraw[1]);

        assertEq(token.balanceOf(alice), initBal - depositAmt);
        assertEq(wToken.balanceOf(alice), depositAmt);
    }
}
