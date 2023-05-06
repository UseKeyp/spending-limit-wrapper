// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "test/TestHelper.t.sol";

/** @dev Trace: -vvvv, No trace: -vv
 * forge test --match-contract Setup -vv
 */

contract Setup is TestHelper {
    /**
     * @dev assert constructor args for name and symbol
     */
    function testDeployment() public {
        assertEq("Futuro", token.name());
        assertEq("FTR", token.symbol());
        assertEq("wFuturo", wToken.name());
        assertEq("wFTR", wToken.symbol());
    }

    /**
     * @dev assert constructor arg for underlying-asset
     */
    function testUnderlyingAsset() public {
        assertEq(address(token), address(wToken.underlying()));
        assertEq(18, wToken.decimals());
    }

    /**
     * @dev assert user's starting balances for underlying-asset
     */
    function testUserBals() public {
        for (uint256 i = 0; i < users.length; i++) {
            assertEq(token.balanceOf(users[i]), initBal);
            assertEq(wToken.balanceOf(users[i]), spends[0]);
        }
    }

    /**
     * @dev should swap max tokens from ERC20 to ERC20Wrapped
     * or revert for non-user
     */
    function testSetup() public {
        setupUsers();

        vm.startPrank(alice);
        assertEq(token.balanceOf(alice), spends[0]);
        assertEq(wToken.balanceOf(alice), initBal);
        (uint256 limit1, uint256 spent1) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit1, spends[3]);
        assertEq(spent1, spends[0]);
        vm.stopPrank();

        vm.startPrank(bob);
        assertEq(token.balanceOf(bob), spends[0]);
        assertEq(wToken.balanceOf(bob), initBal);
        (uint256 limit2, uint256 spent2) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit2, spends[5]);
        assertEq(spent2, spends[0]);
        vm.stopPrank();

        vm.startPrank(cobra);
        assertEq(token.balanceOf(cobra), initBal);
        assertEq(wToken.balanceOf(cobra), spends[0]);
        vm.expectRevert("SL: config does not exist");
        wToken.getAllowanceLimitAndSpent();
        vm.stopPrank();
    }
}
