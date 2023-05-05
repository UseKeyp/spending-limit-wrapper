// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "test/TestHelper.t.sol";

/** @dev Trace: -vvvv, No trace: -vv
 * forge test --match-contract SpendingLimitSetup -vv
 */

contract SpendingLimitSetup is TestHelper {
    /**
     * @dev Assert constructor args for name and symbol
     */
    function testDeployment() public {
        assertEq("Futuro", token.name());
        assertEq("FTR", token.symbol());
        assertEq("wFuturo", wToken.name());
        assertEq("wFTR", wToken.symbol());
    }

    /**
     * @dev Assert constructor arg for underlying-asset
     */
    function testUnderlyingAsset() public {
        assertEq(address(token), address(wToken.underlying()));
        assertEq(18, wToken.decimals());
    }

    /**
     * @dev Assert user's starting balances for underlying-asset
     */
    function testUserBals() public {
        for (uint256 i = 0; i < users.length; i++) {
            assertEq(token.balanceOf(users[i]), 1000);
            assertEq(wToken.balanceOf(users[i]), 0);
        }
    }
}
