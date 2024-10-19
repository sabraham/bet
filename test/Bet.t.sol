// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {Bet} from "../src/Bet.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract BetTest is Test {
    Bet internal bet;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    address public dave = makeAddr("dave");

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Instantiate the contract-under-test.
        bet = new Bet();
        vm.deal(alice, 1 ether);
        vm.deal(bob, 2 ether);
        vm.deal(charlie, 3 ether);
        vm.deal(dave, 4 ether);
    }

    /// @dev Test happy path of a bet being created, funded, and determined.
    function test_HappyPathYesNoYes() external {
        uint256 b = bet.createBet(alice, bob, charlie, 100);

        // alice funds
        vm.startPrank(alice);
        bet.fund{value: 100}(b);
        assertEq(alice.balance, 1 ether - 100 wei);
        vm.stopPrank();

        // bob funds
        vm.startPrank(bob);
        bet.fund{value: 100}(b);
        assertEq(bob.balance, 2 ether - 100 wei);
        vm.stopPrank();

        // charlie judges
        vm.startPrank(charlie);
        bet.determine(b, alice);
        vm.stopPrank();

        assertEq(alice.balance, 1 ether + 100 wei);
        assertEq(bob.balance, 2 ether - 100 wei);
    }

    /// @dev Test happy path of a bet being created, funded, and determined, but no funds first
    function test_HappyPathNoYesYes() external {
        uint256 b = bet.createBet(alice, bob, charlie, 100);

        // bob funds
        vm.startPrank(bob);
        bet.fund{value: 100}(b);
        assertEq(bob.balance, 2 ether - 100 wei);
        vm.stopPrank();

        // alice funds
        vm.startPrank(alice);
        bet.fund{value: 100}(b);
        assertEq(alice.balance, 1 ether - 100 wei);
        vm.stopPrank();

        // charlie judges
        vm.startPrank(charlie);
        bet.determine(b, alice);
        vm.stopPrank();

        assertEq(alice.balance, 1 ether + 100 wei);
        assertEq(bob.balance, 2 ether - 100 wei);
    }

    /// @dev Test reversion if alice/bob funds incorrectly.
    function test_RevertIfIncorrectFunding() external {
        uint256 b = bet.createBet(alice, bob, charlie, 100);

        // alice funds
        vm.startPrank(alice);
        vm.expectRevert();
        bet.fund{value: 200}(b);

        vm.expectRevert();
        bet.fund{value: 50}(b);

        bet.fund{value: 100}(b);
        vm.stopPrank();

        // bob funds
        vm.startPrank(bob);
        vm.expectRevert();
        bet.fund{value: 200}(b);

        vm.expectRevert();
        bet.fund{value: 50}(b);

        bet.fund{value: 100}(b);
        vm.stopPrank();
    }

    /// @dev Test reversion if alice/bob funds twice.
    function test_RevertIfDoubleFunding() external {
        uint256 b = bet.createBet(alice, bob, charlie, 100);

        // alice funds
        vm.startPrank(alice);
        bet.fund{value: 100}(b);
        vm.expectRevert();
        bet.fund{value: 100}(b);
        vm.stopPrank();

        // bob funds
        vm.startPrank(bob);
        bet.fund{value: 100}(b);
        vm.expectRevert();
        bet.fund{value: 100}(b);
        vm.stopPrank();
    }

    /// @dev Test reversion if charlie/dave funds.
    function test_RevertIfIncorrectFunder() external {
        uint256 b = bet.createBet(alice, bob, charlie, 100);

        // charlie funds
        vm.startPrank(charlie);
        vm.expectRevert();
        bet.fund{value: 100}(b);
        vm.stopPrank();

        // dave funds
        vm.startPrank(dave);
        vm.expectRevert();
        bet.fund{value: 100}(b);
        vm.stopPrank();
    }

    /// @dev Test reversion if incorrect judge tries to judge.
    function test_RevertIfIncorrectJudger() external {
        uint256 b = bet.createBet(alice, bob, charlie, 100);

        // alice funds
        vm.startPrank(alice);
        bet.fund{value: 100}(b);
        assertEq(alice.balance, 1 ether - 100 wei);
        vm.stopPrank();

        // bob funds
        vm.startPrank(bob);
        bet.fund{value: 100}(b);
        assertEq(bob.balance, 2 ether - 100 wei);
        vm.stopPrank();

        // alice judges
        vm.startPrank(alice);
        vm.expectRevert();
        bet.determine(b, alice);
        vm.stopPrank();

        // bob judges
        vm.startPrank(bob);
        vm.expectRevert();
        bet.determine(b, bob);
        vm.stopPrank();

        // dave judges
        vm.startPrank(dave);
        vm.expectRevert();
        bet.determine(b, alice);
        vm.stopPrank();
    }

    /// @dev Test reversion if judge determines a winner that is not the yes/no address.
    function test_RevertIfNeitherYesNorNoWinner() external {
        uint256 b = bet.createBet(alice, bob, charlie, 100);

        // alice funds
        vm.startPrank(alice);
        bet.fund{value: 100}(b);
        assertEq(alice.balance, 1 ether - 100 wei);
        vm.stopPrank();

        // bob funds
        vm.startPrank(bob);
        bet.fund{value: 100}(b);
        assertEq(bob.balance, 2 ether - 100 wei);
        vm.stopPrank();

        vm.startPrank(charlie);
        // tries to give winnings to self
        vm.expectRevert();
        bet.determine(b, charlie);

        vm.expectRevert();
        // tries to give winnings to dave
        bet.determine(b, dave);
        vm.stopPrank();
    }

    /// @dev Test that a determination can only be made if the bet is fully funded.
    function test_RevertIfDetermineAndNotFunded() external {
        uint256 b = bet.createBet(alice, bob, charlie, 100);

        // charlie judges early
        vm.startPrank(charlie);
        vm.expectRevert();
        bet.determine(b, alice);
        vm.stopPrank();

        // alice funds
        vm.startPrank(alice);
        bet.fund{value: 100}(b);
        assertEq(alice.balance, 1 ether - 100 wei);
        vm.stopPrank();

        // charlie judges early
        vm.startPrank(charlie);
        vm.expectRevert();
        bet.determine(b, alice);
        vm.stopPrank();

        // bob funds
        vm.startPrank(bob);
        bet.fund{value: 100}(b);
        assertEq(bob.balance, 2 ether - 100 wei);
        vm.stopPrank();

        // charlie judges
        vm.startPrank(charlie);
        bet.determine(b, alice);
        vm.stopPrank();

        assertEq(alice.balance, 1 ether + 100 wei);
        assertEq(bob.balance, 2 ether - 100 wei);
    }
}
