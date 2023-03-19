// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RewardToken} from "../../src/Project2NFTs/part2/Token.sol";  
import {LincolnNFT} from "../../src/Project2NFTs/part2/NFT.sol";  
import {Vault} from "../../src/Project2NFTs/part2/Vault.sol";  


contract NFTStakingRewardsTest is Test {

    RewardToken public rewardToken;  
    LincolnNFT public collection;
    Vault public vault;

    function setUp() public {
        // ERC20 and NFT contracts need to be deployed before the vault
        rewardToken = new RewardToken("Lincoln Reward Token", "LRWD");
        collection = new LincolnNFT();

        vault = new Vault(collection, rewardToken);
        // set Vault contract address as allowedMinter on the rewardtoken

    }

    function testPresale() public view {
    }
}