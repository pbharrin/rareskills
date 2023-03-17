// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/Project2NFTs/OZNFTMerkle.sol";  

contract OZNFTMerkleTest is Test {
    OZNFTMerkle public merkleNFT;

    function setUp() public {
        merkleNFT = new OZNFTMerkle();
    }

    function createMerkelRoot() public pure returns (bytes32) {
        address aa1 = vm.addr(1); 
        return keccak256(abi.encodePacked(aa1));
    }


    /**
    Test if we can add an address to the Merkle tree and then the address
    can buy an NFT in the presale.    
     */
    function testPresale() public {

        // create Merkle Root for valid pre sale addresses
        bytes32 root = createMerkelRoot();
        merkleNFT.setMerkleRoot(root);

        address add1 = vm.addr(1);

        vm.deal(add1, 1 ether);
        vm.startPrank(add1);

        myProof = 
        merkleNFT.presale();

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
