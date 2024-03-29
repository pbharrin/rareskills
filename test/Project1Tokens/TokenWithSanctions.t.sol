// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "../../src/Project1Tokens/TokenWithSanctions.sol";

contract TokenWithSanctionsTest is Test {
    TokenWithSanctions public token;

    // address defaultAdd = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;  //vm.addr(1)
    address constant ADD_1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address constant ADD_2 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {
        token = new TokenWithSanctions("Witch", "WTCH", 1000);
    }

    // check to see if the ban function works
    function testNoAddressBanned() public view {
        // no one banned
        assert(!token.status(ADD_1));
        assert(!token.status(ADD_2));
    }

    function testBanned() public {
        // no one banned
        token.banAddress(ADD_1);
        assert(token.status(ADD_1));
        assert(!token.status(ADD_2));

        // now un-ban ADD_1
        token.unBanAddress(ADD_1);
        assert(!token.status(ADD_1));
    }

    function testBanWrongOwner() public {
        // try to ban without being the owner
        vm.startPrank(ADD_2);
        vm.expectRevert("Only the token admin can ban addresses.");
        token.banAddress(ADD_1);
        vm.stopPrank();
    }

    // make sure you can not sell or buy with a banned address
    function testTransfer() public {
        // send tokens to account 2
        token.transfer(ADD_2, 100);

        // ban address2
        token.banAddress(ADD_1);
        vm.startPrank(ADD_2);
        vm.expectRevert("Sorry the to or from addresses are banned.");
        token.transfer(ADD_1, 100);
        vm.stopPrank();
    }

    /**
     * Test using another form of transfer.
     */
    function testTransferFrom() public {
        token.transfer(vm.addr(2), 200);
        vm.startPrank(vm.addr(2));
        // approve vm.addr(1) to spend tokens
        token.approve(vm.addr(1), 200);
        vm.stopPrank();

        console.log("allowance: %d", token.allowance(vm.addr(2), vm.addr(1)));

        vm.startPrank(vm.addr(1));
        bool transfered = token.transferFrom(vm.addr(2), vm.addr(1), 100);
        assert(transfered);
        vm.stopPrank();

        // now ban addr(2) and try transferFrom again
        token.banAddress(vm.addr(2));

        vm.startPrank(vm.addr(1));
        vm.expectRevert("Sorry the to or from addresses are banned.");
        token.transferFrom(vm.addr(2), vm.addr(1), 100);
        vm.stopPrank();
    }
}
