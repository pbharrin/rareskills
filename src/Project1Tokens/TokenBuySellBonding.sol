// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// for a constant bonding curve amount of tokens you get per eth sent in.
uint constant TOKEN_PER_ETHWEI = 1;

contract TokenBuySellBonding is ERC1363 {
        constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}


    /**
    Internal function for calculating amout of tokens to be received 
    per ETH sent.  This determines the amount to mint, based on a linear
    bonding curve.
     */
    function _amountTokensOut(uint256 ethIn) private view returns (uint){

        // get the total supply 
        uint256 totalSupply = totalSupply();
        uint256 _collateralBalance = totalSupply ** 2 / 2;
        uint256 newTotalSupply = Math.sqrt(2 * (_collateralBalance + ethIn));

        return newTotalSupply - totalSupply;
    }

    /**
    Used to reverse the bonding curve.  We have the number of tokens the user
    wants to sell, and we need to return the amount of eth.  
     */
    function _amountEthOut(uint256 tokenIn) private view returns (uint){ 
        uint256 totalSupply = totalSupply();
        uint256 _collateralBalance = totalSupply ** 2 / 2;
        uint256 newCollateralBalance = (totalSupply - tokenIn) ** 2 / 2;

        return _collateralBalance - newCollateralBalance;
    }

    /**
    Gives the user a hypothetical amount of tokens they would receive from 
    buying.  
     */
    function quoteBuy(uint256 ethIn) public view returns (uint){
        return _amountTokensOut(ethIn);
    }

    /**
    Gives the user a quote of amout of ETH they would recieve from selling
    tokens.
     */
    function quoteSell(uint256 tokenIn) public view returns (uint){
        return _amountEthOut(tokenIn);
    }

    /**
    Recevie is a special function that gets called whenever the contract receives
    ETH.  (Notice no function keyword and no return type.)
     */
    receive() external payable {
        uint tokenCredit = _amountTokensOut(msg.value);
        // set new value in _balances in ERC20 (it is private so need to call function)
        _mint(msg.sender, tokenCredit);
    }
}