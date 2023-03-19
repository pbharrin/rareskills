// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Merkle} from "murky/Merkle.sol";
import "../../src/Project2NFTs/OZNFTMerkle.sol";  

contract OZNFTMerkleTest is Test {
    OZNFTMerkle public merkleNFT;
    address add1 = vm.addr(1);
    address add2 = vm.addr(2);
    address add3 = vm.addr(3);
    address add9 = vm.addr(9);

    // create Merkle Root for valid pre sale addresses
    Merkle m = new Merkle();

    bytes32[] data = new bytes32[](2);

    bytes32 root;
    bytes32[] proof1;

    function setUp() public {
        data[0] = keccak256(abi.encodePacked(add1));
        data[1] = keccak256(abi.encodePacked(add2));

        root = m.getRoot(data);
        proof1 = m.getProof(data, 0);

        merkleNFT = new OZNFTMerkle();
    }


    /**
    Test if we can add an address to the Merkle tree and then the address
    can buy an NFT in the presale.    
     */
    function testPresale() public {

        merkleNFT.setMerkleRoot(root);

        
        vm.deal(add1, 1 ether);
        vm.startPrank(add1);

        merkleNFT.presale{value: 1 ether}(proof1);
        // console.log("amount sent with TXN: %s", amntSent );

        // This should fail because no money was sent.  
        assert(merkleNFT.tokenSupply() == 1 );
        assert(merkleNFT.balanceOf(add1) == 1);
        assert(merkleNFT.ownerOf(0) == add1);

        vm.stopPrank();

        vm.startPrank(add9);
        vm.expectRevert();  // "Invalid merkle proof"
        merkleNFT.presale{value: 1 ether}(proof1);
        vm.stopPrank();
    }

    /**
    Test purchase outside of presale.  
     */
    function testRegularPurchase() public {

        vm.deal(add1, 20 ether);
        vm.startPrank(add1);
        uint256 supplyBefore = merkleNFT.tokenSupply();
        merkleNFT.mint{value: 2 ether}();
        uint256 supplyAfter = merkleNFT.tokenSupply();
        assert(supplyAfter - supplyBefore == 1);

        vm.expectRevert("the price is not correct");
        merkleNFT.mint{value: 1 ether}();


        // check MAX_SUPPLY is controlled
        do {
            merkleNFT.mint{value: 2 ether}();
        } while (merkleNFT.tokenSupply() < merkleNFT.MAX_SUPPLY());
        
        console.log("total supply: %s", merkleNFT.tokenSupply() );

        vm.expectRevert();
        merkleNFT.mint{value: 2 ether}();


        vm.stopPrank();
    }

}
