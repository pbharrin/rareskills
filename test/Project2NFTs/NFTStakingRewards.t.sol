// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RewardToken} from "../../src/Project2NFTs/part2/Token.sol";
import {LincolnNFT} from "../../src/Project2NFTs/part2/NFT.sol";
import {Vault} from "../../src/Project2NFTs/part2/Vault.sol";

contract NFTStakingRewardsTest is Test {
    RewardToken public rewardToken;
    LincolnNFT public collection;
    Vault public vault;

    address constant DEFAULT_ADD = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;

    function setUp() public {
        // ERC20 and NFT contracts need to be deployed before the vault
        rewardToken = new RewardToken("Lincoln Reward Token", "LRWD");
        collection = new LincolnNFT();

        vault = new Vault(collection, rewardToken);

        // set Vault contract address as allowedMinter on the rewardtoken
        rewardToken.addMinter(address(vault));
    }

    // function testBareBack() public view {
    //     console.log(vm.addr(1));
    // }

    function testStake() public {
        // mint an NFT
        collection.mint{value: 1 ether}();
        assert(collection.ownerOf(0) == DEFAULT_ADD);

        // approve the vault to use NFT with tokenID = 0
        collection.approve(address(vault), 0);
        // stake the NFT
        vault.stake(0);

        // check the rewards earned
        uint256 balBefore = rewardToken.balanceOf(DEFAULT_ADD);
        uint256 time0 = block.timestamp;
        console.log("current token balance: %d", balBefore);

        vm.warp(time0 + 1 days); // jump ahead 1 day

        uint256 rewardsEarned = vault.rewardsAvailable(0);
        assert(rewardsEarned == 10 ether);

        // check collectRewards()
        vault.collectRewards(0);
        uint256 balAfter = rewardToken.balanceOf(DEFAULT_ADD);
        console.log("current token balance: %d", balAfter);
        assert(balAfter - balBefore == rewardsEarned);
    }
}
