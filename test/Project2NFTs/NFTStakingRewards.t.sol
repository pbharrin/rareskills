// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {RewardToken} from "../../src/Project2NFTs/part2/Token.sol";
import {LincolnNFT} from "../../src/Project2NFTs/part2/NFT.sol";
import {Vault} from "../../src/Project2NFTs/part2/Vault.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTStakingRewardsTest is Test {
    RewardToken public rewardToken;
    LincolnNFT public collection;
    Vault public vault;

    address constant DEFAULT_ADD = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
    address immutable ADD_1;

    constructor() {
        ADD_1 = vm.addr(1);
    }

    function setUp() public {
        // ERC20 and NFT contracts need to be deployed before the vault
        rewardToken = new RewardToken("Lincoln Reward Token", "LRWD");
        collection = new LincolnNFT();

        vault = new Vault(collection, rewardToken);

        // set Vault contract address as allowedMinter on the rewardtoken
        rewardToken.addMinter(address(vault));
    }

    function testERC20() public {
        vm.expectRevert("only allowed minters can mint rewards");
        rewardToken.mint(address(this), 100);

        rewardToken.addMinter(address(this));
        rewardToken.mint(address(this), 100);
        // check balance
        assert(rewardToken.balanceOf(address(this)) == 100);

        rewardToken.removeMinter(address(this));
        vm.expectRevert("only allowed minters can mint rewards");
        rewardToken.mint(address(this), 100);
    }

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

        vm.roll(block.number + 7110); // jump ahead 1 day

        uint256 rewardsEarned = vault.rewardsAvailable(0);
        assert(rewardsEarned == 10 ether);

        // check collectRewards()
        vault.collectRewards(0);
        uint256 balAfter = rewardToken.balanceOf(DEFAULT_ADD);
        assert(balAfter - balBefore == rewardsEarned);
    }

    // See if vault.stake() fails properly.
    function testStakeFails() public {
        collection.mint{value: 1 ether}();
        collection.approve(address(vault), 0);
        vault.stake(0);

        // test staking an NFT already staked
        vm.expectRevert("You do not own this NFT");
        vault.stake(0);

        // test staking an NFT owned by someone else
        vm.startPrank(ADD_1);
        vm.expectRevert("You do not own this NFT");
        vault.stake(0);
        vm.stopPrank();
    }

    function testUnStakeFails() public {
        collection.mint{value: 1 ether}();
        collection.approve(address(vault), 0);
        vault.stake(0);

        vm.startPrank(ADD_1);
        vm.expectRevert("You are not the owner of this NFT");
        vault.unStake(0);
        vm.stopPrank();

        // make sure it was unstaked
        vault.unStake(0);
        vm.expectRevert("You must own an NFT to collect rewards on it.");
        vault.collectRewards(0);
    }

    /**
     * Test staking the wrong way gets stopped.
     */
    function testWrongWayToStake() public {
        vm.deal(ADD_1, 10 ether);
        vm.startPrank(ADD_1);

        // try transfering directly to the vault
        collection.mint{value: 1 ether}();
        vm.expectRevert("You need to use stake");
        collection.safeTransferFrom(ADD_1, address(vault), 0);
        vm.stopPrank();

        // try a poorly designed NFT minting directly to vault
        BadNFT badNFT = new BadNFT();
        vm.expectRevert("Cannot send nfts to Vault directly");
        badNFT.safeMintDirectly(address(vault));
    }

    /**
     * See if the NFT price check and MAX_SUPPLY are enforced.
     */
    function testMintFail() public {
        vm.expectRevert("the price is not correct");
        collection.mint{value: 10 ether}();

        for (uint256 i = 0; i < collection.MAX_SUPPLY(); i++) {
            collection.mint{value: 1 ether}();
        }
        vm.expectRevert("too many NFTs minted");
        collection.mint{value: 1 ether}();
    }

    /**
     * Make sure the owner can withdraw funds.
     */
    function testWithDraw() public {
        vm.deal(ADD_1, 10 ether);
        collection.mint{value: 1 ether}();
        collection.mint{value: 1 ether}();

        uint256 contactBalanceBefore = address(collection).balance;
        uint256 balanceBeforeWithdraw = DEFAULT_ADD.balance;
        collection.withdraw();
        uint256 balanceAfterWithdraw = DEFAULT_ADD.balance;
        assert(contactBalanceBefore == balanceAfterWithdraw - balanceBeforeWithdraw);
    }

    /**
     * See if withdraw will fail if the caller cannot receive.
     */
    function testWithdrawFail() public {
        collection.mint{value: 1 ether}();
        NoReceive noReceiver = new NoReceive();
        vm.expectRevert("funds cannot be sent");
        noReceiver.withdraw(); // calls withdwaw but should fail, because caller has not recevie()
    }

    function testNotOwnerWithdraw() public {
        vm.startPrank(ADD_1);
        vm.expectRevert("Ownable: caller is not the owner");
        collection.withdraw();
        vm.stopPrank();
    }

    function testRenounce() public {
        vm.expectRevert("cannot renounce ownership");
        collection.renounceOwnership();
    }

    function testTransfer() public {
        vm.expectRevert("cannot transfer ownership");
        collection.transferOwnership(ADD_1);
    }

    receive() external payable {
        console.log("the contract receive was called");
    }
}

// NFT for testing incorrect way to send to Vault
contract BadNFT is ERC721 {
    uint256 public tokenSupply = 0; // amount of NFTs currently minted

    constructor() ERC721("BadNFT", "BDNF") {}

    function safeMintDirectly(address toAdd) public {
        ++tokenSupply;
        _safeMint(toAdd, tokenSupply - 1);
    }
}

// Contract with no receive() function meant to fail withdraw.
contract NoReceive {
    LincolnNFT public immutable _collection;

    constructor() {
        _collection = new LincolnNFT();
    }

    function withdraw() external {
        _collection.withdraw();
    }
}
