// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Project1Tokens/TokenBuySellBonding.sol";  

contract TokenBuySellBondingTest is Test {
    TokenBuySellBonding public token;

    address add1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address add2 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {
        token = new TokenBuySellBonding("Witch", "WTCH");
    }
}