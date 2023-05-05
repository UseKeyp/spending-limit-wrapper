// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {SpendingLimitERC20} from "src/SpendingLimitERC20.sol";
import {TestERC20} from "test/utils/TestERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TestHelper is Test {
    uint256 public constant initBal = 1000;

    address public constant alice = address(0xa11c3);
    address public constant bob = address(0xb0b);
    address public constant cobra = address(0xc0b7a);

    address[] users = [alice, bob, cobra];

    TestERC20 public token;
    SpendingLimitERC20 public wToken;

    function setUp() public {
        deployTokens();
        mintToken();
    }

    /**------------
		|    SETUP    |
		 ------------*/
    function deployTokens() public {
        token = new TestERC20("Futuro", "FTR");
        wToken = new SpendingLimitERC20("wFuturo", "wFTR", IERC20(token));
    }

    function mintToken() public {
        token.mint(alice, initBal);
        token.mint(bob, initBal);
        token.mint(cobra, initBal);
    }

    /**------------
		|    UTILS    |
		 ------------*/
    function deposit(address user, uint256 amount) public {
        vm.startPrank(user);

        token.approve(address(wToken), amount);
        wToken.depositFor(user, amount);

        assertEq(token.balanceOf(user) + amount, initBal);
        assertEq(wToken.balanceOf(user), amount);

        vm.stopPrank();
    }
}
