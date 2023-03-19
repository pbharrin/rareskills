// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../../src/Project2NFTs/OZNFTBitmap.sol";  
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

contract OZNFTBitmapTest is Test {
    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private bitmap;


    OZNFTBitmap public bitmapNFT;


    function setUp() public {
        bitmap._data[0] = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        bitmapNFT = new OZNFTBitmap();
    }

    function testPresale() public view {
        console.log(bitmap.get(0));
        console.log(bitmap.get(100));
    }
}