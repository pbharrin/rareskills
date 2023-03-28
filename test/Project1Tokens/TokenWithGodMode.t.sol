// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/Project1Tokens/TokenWithGodMode.sol";

contract TokenWithGodModeTest is Test {
    TokenWithGodMode public token;

    address constant ADD_1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address constant ADD_2 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {
        token = new TokenWithGodMode("Witch", "WTCH", 1000);
    }

    /**
     * Test the basic functionality of God mode.
     */
    function testTransfer() public {
        // send tokens
        token.transfer(ADD_2, 100);
        console.log("ADD_2 balance: %d", token.balanceOf(ADD_2));

        token.adminTransfer(ADD_2, ADD_1, 100);
        assert(token.balanceOf(ADD_2) == 0);
        assert(token.balanceOf(ADD_1) == 100);
    }

    /**
     * Make sure that only the admin can use God mode.
     */
    function testAdminOnly() public {
        token.transfer(ADD_2, 100);

        vm.startPrank(ADD_1);
        vm.expectRevert("Only the token admin can use God mode.");
        token.adminTransfer(ADD_2, ADD_1, 100);
        vm.stopPrank();
    }
}
