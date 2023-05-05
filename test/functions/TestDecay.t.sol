// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// forge test --match-contract TestDecay -vv

contract TestDecay is Test {
    function testDecay() public {
        uint256 hl0 = decay(0, 10000);
        uint256 hl1 = decay(1, 10000);
        uint256 hl2 = decay(2, 10000);
        uint256 hl3 = decay(3, 10000);
        uint256 hl4 = decay(4, 10000);

        assertEq(hl0, 10000);
        assertEq(hl1, 5000);
        assertEq(hl2, 2500);
        assertEq(hl3, 1250);
        assertEq(hl4, 625);
    }

    function decay(uint256 n, uint256 amount) public returns (uint256) {
        if (n == 0) return amount;
        if (n == 1) return amount / 2;
        else return decay(n - 1, amount / 2);
    }
}
