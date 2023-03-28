// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract OpenZeppelinNFT is ERC721, Ownable {
    uint256 public tokenSupply = 0; // amount of NFTs currently minted
    uint256 public constant MAX_SUPPLY = 10;
    uint256 public constant PRICE = 1 ether;

    constructor() ERC721("MySweetNFT", "MSNT") {}

    function mint() external payable {
        require(tokenSupply < MAX_SUPPLY);
        require(msg.value != PRICE, "the price is not correct");
        _mint(msg.sender, tokenSupply);
        tokenSupply++;
    }

    /**
     * Only the owner can withdraw funds.
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function renounceOwnership() public pure override {
        require(false, "cannot renounce ownership");
    }

    function transferOwnership(address) public pure override {
        require(false, "cannot transfer ownership");
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmY96okp5ZLkSEyKu5m6tbes83BAEGRsfdkk2akbrMP9Fg/";
    }
}
