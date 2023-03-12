// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Project1Tokens/TokenWithSanctions.sol";  

contract TokenWithSanctionsTest is Test {
    TokenWithSanctions public token;

    address add1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address add2 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {
        token = new TokenWithSanctions("Witch", "WTCH");
    }

    // check to see if the ban function works
    function testNoAddressBanned() view public {
        // no one banned
        assert(!token.status(add1));
        assert(!token.status(add2));
    }

    function testBanned() public {
        // no one banned
        token.banAddress(add1);
        assert(token.status(add1));
        assert(!token.status(add2));

        // now un-ban add1
        token.unBanAddress(add1);
        assert(!token.status(add1));
    }

    function testBanWrongOwner() public {
        // try to ban without being the owner
        vm.startPrank(add2);
        vm.expectRevert("Only the token admin can ban addresses.");
        token.banAddress(add1);
        vm.stopPrank();
    }

    function testTransfer() public {
        // send tokens
        token.transfer(add2, 100);
        // ban address2 
        token.banAddress(add1);
        vm.startPrank(add2);
        vm.expectRevert("Sorry the to or from addresses are banned.");
        token.transfer(add1, 100);
        vm.stopPrank();
    }

}
