// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ERC20SpendingLimit} from "src/ERC20SpendingLimit.sol";
import {ERC20Test} from "test/utils/ERC20Test.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TestHelper is Test {
    // token amounts
    uint256 public constant initBal = 1000 * 1e18;
    uint256 public constant depositAmt = 100 * 1e18;
    uint256[] public withdraw = [80 * 1e18, 120 * 1e18];
    uint256[] public spends = [
        0,
        100 * 1e18,
        200 * 1e18,
        300 * 1e18,
        400 * 1e18,
        500 * 1e18,
        600 * 1e18,
        700 * 1e18,
        800 * 1e18,
        900 * 1e18
    ];

    // user addresses
    address public constant alice = address(0xa11c3);
    address public constant bob = address(0xb0b);
    address public constant cobra = address(0xc0b7a);

    // user address array
    address[] public users = [alice, bob, cobra];

    // config settings arrays
    uint256[] public all_period = [7 days, 30 days];
    uint256[] public app_period = [30 days, 180 days];
    uint256[] public decay_int = [7 days, 30 days];

    // token contracts
    ERC20Test public token;
    ERC20SpendingLimit public wToken;

    /**
     * @dev deploy token contracts and mint underlying asset to users
     */
    function setUp() public {
        deployTokens();
        mintToken();
    }

    /**------------
		|    SETUP    |
		 ------------*/
    function deployTokens() public {
        token = new ERC20Test("Futuro", "FTR");
        wToken = new ERC20SpendingLimit("wFuturo", "wFTR", IERC20(token));
    }

    function mintToken() public {
        token.mint(alice, initBal);
        token.mint(bob, initBal);
        token.mint(cobra, initBal);
    }

    /**------------
		|    UTILS    |
		 ------------*/

    /**
     * @dev deposit max tokens
     */
    function deposit(address user, uint256 amount) public {
        vm.startPrank(user);

        token.approve(address(wToken), amount);
        wToken.depositFor(user, amount);

        assertEq(token.balanceOf(user) + amount, initBal);
        assertEq(wToken.balanceOf(user), amount);

        vm.stopPrank();
    }

    /**
     * @dev set UserConfig and deposit max tokens
     */
    function configAndDeposit(
        address user,
        uint256 _spendingLimit,
        uint256 _allowancePeriod,
        uint256 _approvalPeriod,
        uint256 _decayInterval
    ) public {
        vm.startPrank(user);

        wToken.setCustomConfig(
            _spendingLimit,
            _allowancePeriod,
            _approvalPeriod,
            _decayInterval
        );

        token.approve(address(wToken), initBal);
        wToken.depositFor(user, initBal);

        vm.stopPrank();
    }

    /**
     * @dev setup multiple users config and swaps
     */
    function setupUsers() public {
        configAndDeposit(
            alice,
            spends[3],
            all_period[0],
            app_period[0],
            decay_int[0]
        );

        configAndDeposit(
            bob,
            spends[5],
            all_period[1],
            app_period[1],
            decay_int[1]
        );
    }

    /**
     * @dev move time `forward`, and enforce correct current time `_now`
     */
    function warpForward(uint256 forward, uint256 _now) public {
        vm.warp(block.timestamp + forward);
        assertEq(block.timestamp, _now + 1 seconds);
    }
}
