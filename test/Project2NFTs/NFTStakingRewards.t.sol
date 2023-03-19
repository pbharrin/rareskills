// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../../src/Project2NFTs/part2/OZNFTBitmap.sol";  

contract NFTStakingRewardsTest is Test {

    OZNFTBitmap public bitmapNFT;


    function setUp() public {
        // ERC20 and NFT contracts need to be deployed before the vault

        bitmapNFT = new OZNFTBitmap();
    }

    function testPresale() public view {
    }
}