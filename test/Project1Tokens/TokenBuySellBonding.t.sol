// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Project1Tokens/TokenBuySellBonding.sol";  

contract TokenBuySellBondingTest is Test {
    TokenBuySellBonding public token;

    address defaultAdd = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;

    address add1 = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    address add2 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {
        token = new TokenBuySellBonding("Witch", "WTCH");
    }

    /**
    We should have a fail if we try to sell more than the total supply.
     */
    function testSaleOnZeroTotalSupply() public{
        
        assert(token.totalSupply() == 0);
        console.log("contract address: %s", address(token));

        vm.expectRevert("Not enough totalSupply for this.");
        token.quoteSell(100);
    }

    /**
    Test when we buy the total supply goes up, and that tokens get more expensive.  
     */
    function testBondingBuy() public {
        
        console.log("totalSupply: %d", token.totalSupply());
        uint buyQuoteBefore = token.quoteBuy(100);
        console.log("token.quoteBuy(100): %d", buyQuoteBefore);
        (bool sent, ) = address(token).call{value: 100}("");  // recommended way of sending ETH to a contract
        assert(sent);
        
        assert(token.totalSupply() == buyQuoteBefore);
        console.log("totalSupply: %d", token.totalSupply());

        // make sure the tokens are in our account
        assert(buyQuoteBefore == token.balanceOf(defaultAdd));
        
        uint buyQuoteAfter = token.quoteBuy(100);
        console.log("token.quoteBuy(100): %d", buyQuoteAfter);
        assert(buyQuoteAfter < buyQuoteBefore);
    }

    function testBondingSell() public {
        address someRandomUser = vm.addr(1);
        vm.deal(someRandomUser, 10 ether);
        console.log("someRandomUser: %s", someRandomUser);
        vm.startPrank(someRandomUser);
        

        (bool sent, ) = address(token).call{value: 1000000000000}("");  // recommended way of sending ETH to a contract
        assert(sent);
        console.log("balance of our token contract: %s", address(token).balance);
        uint256 allOurTokens = token.balanceOf(someRandomUser);
        console.log("number of tokens: %d", allOurTokens);
        console.log("token.quoteSell(allOurTokens): %d", token.quoteSell(allOurTokens));
        // sell tokens back (reverse transaction)
        (bool sellWorked, address whoWeRefunded) = token.sell(allOurTokens);
        console.log("sending tokens to: %s", whoWeRefunded);
        console.log("sell worked: %s", sellWorked);
        console.log("original sender's eth balance: %s", someRandomUser.balance);
        console.log("totalSupply: %d", token.totalSupply());
        console.log("balance of our token contract: %s", address(token).balance);
        vm.stopPrank();
    }
}