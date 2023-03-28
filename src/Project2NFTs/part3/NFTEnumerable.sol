// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFTEnumerable is ERC721Enumerable {
    uint256 public tokenSupply = 0; // amount of NFTs currently minted
    uint256 public constant MAX_SUPPLY = 20;
    uint256 public constant PRICE = 1 ether;
    address owner;

    constructor() ERC721("Enumer", "ENUM") {
        owner = msg.sender;
    }

    /**
     * NFT buying mint.
     */
    function mint() external payable {
        require(tokenSupply < MAX_SUPPLY);
        require(msg.value == PRICE, "the price is not correct");
        _mint(msg.sender, tokenSupply + 1);
        tokenSupply++;
    }

    /**
     * Only the owner can withdraw funds.  This allows the funds an exit path.
     */
    function withdraw() external {
        require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * Function for testing to mint many NFTs, no checks.
     */
    function massFreeMint(uint256 numMint) external {
        for (uint256 i = 0; i < numMint; i++) {
            _mint(msg.sender, tokenSupply + 1);
            tokenSupply++;
        }
    }
}
