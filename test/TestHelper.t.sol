// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// forge test --match-contract TestHelper -vv

contract TestHelper is Test {
    address alice = address(0xa11c3);
    address bob = address(0xb0b);
    address cobra = address(0xc0b7a);

    function testDecay() public {
        uint256 hl0 = decay(0, 100);
        uint256 hl1 = decay(1, 100);
        uint256 hl2 = decay(2, 100);
        uint256 hl3 = decay(3, 100);
        uint256 hl4 = decay(4, 100);
        uint256 hl5 = decay(5, 100);

        assertEq(hl0, 100);
        assertEq(hl1, 50);
        assertEq(hl2, 25);
        assertEq(hl3, 12.5);
        assertEq(hl4, 6.25);
        assertEq(hl5, 3.125);
    }

    function decay(uint256 n, uint256 amount) public returns (uint256) {
        if (n == 0) return amount;
        if (n == 1) return amount / 2;
        else return decay(n - 1, amount / 2);
    }
}
