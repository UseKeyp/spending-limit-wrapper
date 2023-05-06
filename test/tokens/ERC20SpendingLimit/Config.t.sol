// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestHelper} from "test/TestHelper.t.sol";

/** @dev Trace: -vvvv, No trace: -vv
 * forge test --match-contract Config -vv
 */

contract Config is TestHelper {
    /**
     * @dev should set UserConfig to default values
     */
    function testSetDefaultConfig() public {
        vm.startPrank(alice);
        wToken.setDefaultConfig();

        (uint256 start, uint256 end) = wToken.getAllowanceStartAndEnd();
        assertEq(start, 1 seconds);
        assertEq(end, 30 days + 1 seconds);

        (uint256 limit, uint256 spent) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit, initBal);
        assertEq(spent, spends[0]);

        (uint256 approval, uint256 decay) = wToken.getApprovalPeriodAndDecay();
        assertEq(approval, 182.5 days);
        assertEq(decay, 30 days);
    }

    /**
     * @dev should set UserConfig to custom values
     */
    function testSetCustomConfig() public {
        vm.startPrank(bob);
        wToken.setCustomConfig(
            spends[5],
            all_period[1],
            app_period[1],
            decay_int[1]
        );

        (uint256 start, uint256 end) = wToken.getAllowanceStartAndEnd();
        assertEq(start, 1 seconds);
        assertEq(end, all_period[1] + 1 seconds);

        (uint256 limit, uint256 spent) = wToken.getAllowanceLimitAndSpent();
        assertEq(limit, spends[5]);
        assertEq(spent, 0);

        (uint256 approval, uint256 decay) = wToken.getApprovalPeriodAndDecay();
        assertEq(approval, app_period[1]);
        assertEq(decay, decay_int[1]);
    }
}
