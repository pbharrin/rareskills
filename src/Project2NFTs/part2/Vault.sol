// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LincolnNFT} from "./NFT.sol";
import {RewardToken} from "./Token.sol";

contract Vault is IERC721Receiver, Ownable {

    uint256 constant REWARDS_PER_DAY = 10 ether; // 10 tokens are rewarded, the token uses 18 decimals.

    // struct for storing info per staked NFT
    struct StakedNFT {
        uint256 nftId;
        address owner;
        uint256 timestamp;
    }
    
    LincolnNFT _collection;    // Ref to our NFT contract
    RewardToken _rewardToken;  // ref to our token contract

    // events may be useful
    event NFTStaked(uint256 nftId, address owner);
    event NFTRemoved(uint256 nftId, address owner);
    event RewardsCollected(uint256 nftId, address owner, uint256 rewardAmount);

    mapping(uint256 => StakedNFT) public vault;  // map to get stakedNFT struct by tokenID

    constructor(LincolnNFT collection, RewardToken rewardToken){
        _collection = collection;
        _rewardToken = rewardToken;
    }

    // Stake, this could be a loop to allow multiple NFTs to be staked at once.
    // Before this is called, the vault needs to be approved for this tokenID.
    function stake(uint256 tokenID) external {
        require(_collection.ownerOf(tokenID) == msg.sender, "You do not own this NFT");
        require(vault[tokenID].nftId == 0, "this token is already staked");

        _collection.transferFrom(msg.sender, address(this), tokenID);

        vault[tokenID] = StakedNFT({
            nftId: tokenID,
            owner: msg.sender,
            timestamp: block.timestamp  // it may be better to use block number
        });
        emit NFTStaked(tokenID, msg.sender);
    }

    /**
    UnStake removes the token from the vault and returns ownership to the 
    original owner.  This must be called by the orignal owner.  
     */
    function unStake(uint256 tokenID) external {
        StakedNFT memory currentlyStaked = vault[tokenID];
        require(msg.sender == currentlyStaked.owner, "You are not the owner of this NFT");

        delete vault[tokenID];
        emit NFTRemoved(tokenID, msg.sender);
        _collection.transferFrom(address(this), msg.sender, tokenID);
    }

    /**
    This actually collects rewards, and will reset the timestamp of the staking 
    to the current timestamp.  
    
    Could add an option to unstake at the same time to save users gas fees.  
     */
    function collectRewards(uint256 tokenID) external {
        (uint256 rewards, address owner) = _rewards(tokenID);
        require(owner == msg.sender, "You must own an NFT to collect rewards on it.");

        // transfer rewards to the owner
        _rewardToken.mint(owner, rewards);

        // reset the struct in the vault with the current timestamp/blocknumber
        vault[tokenID] = StakedNFT({
            nftId: tokenID,
            owner: msg.sender,
            timestamp: block.timestamp  // it may be better to use block number
        });
    }

    /**
    Displays the amount of rewards earned for a given tokenID.
     */
    function rewardsAvailable(uint256 tokenID) external view returns (uint256) {
        (uint256 rewards, ) = _rewards(tokenID);
        return rewards;
    }

    /**
    Interal function to calculate rewards earned.
    */
    function _rewards(uint256 tokenID) private view returns (uint256, address) {
        StakedNFT memory currentlyStaked = vault[tokenID];
        uint256 rw = REWARDS_PER_DAY * (block.timestamp - currentlyStaked.timestamp) / 1 days;
        return (rw, currentlyStaked.owner);
    }

    // for save transfer usage.
    function onERC721Received(address, address from, uint256, bytes calldata
        ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send nfts to Vault directly");
      return IERC721Receiver.onERC721Received.selector;
    }

}