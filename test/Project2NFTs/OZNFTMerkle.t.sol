// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import "forge-std/console.sol";
import {Test, console} from "forge-std/Test.sol";

import "../../src/Project2NFTs/OZNFTMerkle.sol";  

contract OZNFTMerkleTest is Test {
    OZNFTMerkle public merkleNFT;
    address add1 = vm.addr(1);
    address add2 = vm.addr(2);
    address add3 = vm.addr(3);

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

        uint256 amntSent = merkleNFT.presale{value: 1 ether}(proof1);
        console.log("amount sent with TXN: %s", amntSent );

        // This should fail because no money was sent.  
        assert(merkleNFT.tokenSupply() == 1 );
        assert(merkleNFT.balanceOf(add1) == 1);
        assert(merkleNFT.ownerOf(0) == add1);

        vm.stopPrank();

        vm.startPrank(add3);
        vm.expectRevert("Invalid merkle proof");
        // merkleNFT.presale(proof1);
        merkleNFT.presale{value: 1 ether}(proof1);
        vm.stopPrank();
    }

    /**
    Make sure that only the admin can use God mode.  
     */
    // function testAdminOnly() public {

    //     token.transfer(add2, 100);

    //     vm.startPrank(add1);
    //     vm.expectRevert("Only the token admin can use God mode.");
    //     token.transfer(add2, add1, 100);
    //     vm.stopPrank();
    // }

}
