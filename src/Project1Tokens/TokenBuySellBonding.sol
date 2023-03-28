// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC1363, ERC20} from "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract TokenBuySellBonding is ERC1363 {
    constructor(string memory _nameIn, string memory _symbolIn) ERC20(_nameIn, _symbolIn) {}

    /**
     * Internal function for calculating amout of tokens to be received
     * per ETH sent.  This determines the amount to mint, based on a linear
     * bonding curve.
     */
    function _amountTokensOut(uint256 ethIn) private view returns (uint256) {
        // get the total supply
        uint256 totalSup = totalSupply();
        uint256 _collateralBalance = totalSup ** 2 / 2;
        uint256 newTotalSupply = Math.sqrt(2 * (_collateralBalance + ethIn));

        return newTotalSupply - totalSup;
    }

    /**
     * Used to reverse the bonding curve.  We have the number of tokens the user
     * wants to sell, and we need to return the amount of eth.
     */
    function _amountEthOut(uint256 tokenIn) private view returns (uint256) {
        uint256 totalSup = totalSupply();
        require(totalSup >= tokenIn, "Not enough totalSupply for this.");
        uint256 _collateralBalance = totalSup ** 2 / 2;
        uint256 newCollateralBalance = (totalSup - tokenIn) ** 2 / 2;

        return _collateralBalance - newCollateralBalance;
    }

    /**
     * Gives the user a hypothetical amount of tokens they would receive from
     * buying.
     */
    function quoteBuy(uint256 ethIn) public view returns (uint256) {
        return _amountTokensOut(ethIn);
    }

    /**
     * Gives the user a quote of amout of ETH they would recieve from selling
     * tokens.
     */
    function quoteSell(uint256 tokenIn) public view returns (uint256) {
        return _amountEthOut(tokenIn);
    }

    /**
     * Recevie is a special function that gets called whenever the contract receives
     * ETH.  (Notice no function keyword and no return type.)
     */
    receive() external payable {
        uint256 tokenCredit = _amountTokensOut(msg.value);
        // set new value in _balances in ERC20 (it is private so need to call function)
        _mint(msg.sender, tokenCredit);
    }

    /**
     * Sell the tokens for ETH.  Will fail if the ETH collateral cannot be sent
     * back to the sender.
     * If sucessful will return the amount of ETH collateral sent back to user.
     */
    function sell(uint256 tokenIn) public returns (uint256) {
        uint256 amountEth = _amountEthOut(tokenIn);
        require(address(this).balance >= tokenIn);

        // reduce the total supply by tokenIn.
        _burn(msg.sender, tokenIn);

        (bool sent,) = payable(msg.sender).call{value: amountEth}(abi.encode(1));
        require(sent);

        return amountEth;
    }
}
