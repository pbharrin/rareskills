// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/Project1Tokens/TokenWithGodMode.sol";  

contract TokenWithGodModeTest is Test {
    TokenWithGodMode public token;

    address add1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address add2 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {
        token = new TokenWithGodMode("Witch", "WTCH", 1000);
    }


    /**
    Test the basic functionality of God mode.  
     */
    function testTransfer() public {
        // send tokens
        token.transfer(add2, 100);
        console.log("add2 balance: %d", token.balanceOf(add2));
        
        token.adminTransfer(add2, add1, 100);
        assert(token.balanceOf(add2) == 0);
        assert(token.balanceOf(add1) == 100);
    }

    /**
    Make sure that only the admin can use God mode.  
     */
    function testAdminOnly() public {

        token.transfer(add2, 100);

        vm.startPrank(add1);
        vm.expectRevert("Only the token admin can use God mode.");
        token.adminTransfer(add2, add1, 100);
        vm.stopPrank();
    }

}
