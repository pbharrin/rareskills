// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Test, console} from "forge-std/Test.sol";
// import {DSTest} from "ds-test/test.sol";
import "../../src/Project1Tokens/TokenBuySellBonding.sol";

contract TokenBuySellBondingTest is Test {
    TokenBuySellBonding public token;

    // defult EOA from which transactions are sent
    address defaultAdd = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;

    function setUp() public {
        token = new TokenBuySellBonding("Witch", "WTCH");
    }

    /**
     * We should have a fail if we try to sell more than the total supply.
     */
    function testSaleOnZeroTotalSupply() public {
        assert(token.totalSupply() == 0);
        console.log("contract address: %s", address(token));

        vm.expectRevert("Not enough totalSupply for this.");
        token.quoteSell(100);
    }

    /**
     * Test when we buy the total supply goes up, and that tokens get more expensive.
     */
    function testBondingBuy() public {
        console.log("totalSupply: %d", token.totalSupply());
        uint256 buyQuoteBefore = token.quoteBuy(100);
        console.log("token.quoteBuy(100): %d", buyQuoteBefore);
        (bool sent,) = address(token).call{value: 100}(""); // recommended way of sending ETH to a contract
        assert(sent);

        assert(token.totalSupply() == buyQuoteBefore);
        console.log("totalSupply: %d", token.totalSupply());

        // make sure the tokens are in our account
        assert(buyQuoteBefore == token.balanceOf(defaultAdd));

        uint256 buyQuoteAfter = token.quoteBuy(100);
        console.log("token.quoteBuy(100): %d", buyQuoteAfter);
        assert(buyQuoteAfter < buyQuoteBefore);
    }

    /**
     * Test selling tokens back to contact.
     */
    function testBondingSell() public {
        address someRandomUser = vm.addr(1);
        uint256 userStartingBalanceETH = 10 ether;
        vm.deal(someRandomUser, userStartingBalanceETH);
        vm.startPrank(someRandomUser);
        uint256 amountWei2Send = 1_000_000_000_000;

        (bool sent,) = address(token).call{value: amountWei2Send}(""); // recommended way of sending ETH to a contract
        assert(sent);

        // make sure the contract got the ETH we sent
        uint256 contractETHBalance = address(token).balance;
        console.log("ETH balance of our token contract: %s", contractETHBalance);
        assert(contractETHBalance == amountWei2Send);

        // make sure we have some tokens
        uint256 allOurTokens = token.balanceOf(someRandomUser);
        assert(allOurTokens > 0);
        console.log("number of tokens user received: %d", allOurTokens);

        uint256 userETHBalanceBeforeSell = someRandomUser.balance;

        // sell back tokens
        uint256 saleQuote = token.quoteSell(allOurTokens);
        console.log("token.quoteSell(allOurTokens): %d", saleQuote);
        uint256 saleAmount = token.sell(allOurTokens);
        assert(saleAmount == saleQuote);

        // make sure the ETH collateral has made it back to the user
        assert(someRandomUser.balance == userETHBalanceBeforeSell + saleAmount);
        assert(token.totalSupply() == 0);

        // check the before and after are within 1% of each other
        uint256 delta = userStartingBalanceETH / 100;
        assertApproxEqRel(userStartingBalanceETH, someRandomUser.balance, delta);

        vm.stopPrank();
    }
}
