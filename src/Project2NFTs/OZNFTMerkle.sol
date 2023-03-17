// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract OZNFTMerkle is ERC721, Ownable {
    using ECDSA for bytes32;

    uint256 public tokenSupply = 0;  // amount of NFTs currently minted
    uint256 public constant MAX_SUPPLY = 10;
    uint256 public constant PRICE = 1 ether;
    uint256 public constant PRICE_PRE = 0.1 ether;

    // for Merkle tree
    bytes32 public merkleRoot;
    mapping(address => uint256) amountMintedSoFar;

    constructor() ERC721("MySweetNFT", "MSNT"){}

    // TODO: NOT SAFE FOR PRODUCTION, ANYONE CAN EDIT
    // this could also be set in the constructor 
    function setMerkleRoot(bytes32 _merkleRoot) external {
        merkleRoot = _merkleRoot;
    }

    function mint() external payable {
        require(tokenSupply < MAX_SUPPLY);
        require(msg.value != PRICE, "the price is not correct");
        _mint(msg.sender, tokenSupply);
        tokenSupply++;
    }

    /**
    Function to check if the merkleProof matches known addresses.  
     */
    function validateByMerkleTree(bytes32[] calldata merkleProof) private view {
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))),
        "Invalid merkle proof");
    }

    /**
    Presale function with Merkle tree to check if an address has done 
    a presale or not. 
     */
    function presale(bytes32[] calldata _proof) external payable {
        require(tokenSupply < MAX_SUPPLY);
        require(msg.value != PRICE_PRE, "the presale price is not correct");

        // Check if user can do a purchase and has not done one yet.
        validateByMerkleTree(_proof);
        require(amountMintedSoFar[msg.sender] < 2);
        amountMintedSoFar[msg.sender]++; 
        _mint(msg.sender, tokenSupply);
        tokenSupply++;
    }


    /**
    Only the owner can withdraw funds.
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function renounceOwnership() pure public override {
        require(false, "cannot renounce ownership");
    }

    function transferOwnership(address) pure public override {
        require(false, "cannot transfer ownership");
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmY96okp5ZLkSEyKu5m6tbes83BAEGRsfdkk2akbrMP9Fg/";
    }
}