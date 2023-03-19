// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LincolnNFT} from "./NFT.sol";
import {RewardToken} from "./Token.sol";

contract Vault is IERC721Receiver, Ownable {

    // struct for storing info per staked NFT
    struct StakedNFT {
        uint256 nftId;
        address owner;
        uint48 timestamp;
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

    // stake

    // removeStaked

    // collectRewards

    // rewardsAvailable (see earned rewards)

      function onERC721Received(address, address from, uint256, bytes calldata
        ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send nfts to Vault directly");
      return IERC721Receiver.onERC721Received.selector;
    }

}