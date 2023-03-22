// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract LincolnNFT is ERC721, Ownable {

    uint256 public tokenSupply = 0;  // amount of NFTs currently minted
    uint256 public constant MAX_SUPPLY = 10;
    uint256 public constant PRICE = 1 ether;

    constructor() ERC721("LincolnNFT", "LNCN"){}

    function mint() external payable {
        require(tokenSupply < MAX_SUPPLY);
        require(msg.value == PRICE, "the price is not correct");
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
}