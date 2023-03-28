// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC1363, ERC20} from "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC1363, Ownable {
    // Mapping to create an allowed list of addresses that can mint.
    // This is needed for the vault address to mint rewards tokens.
    mapping(address => bool) private allowedMinters;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /**
     * Mint function for sending rewards tokens, can be done by valid
     * allowedMinters.
     */
    function mint(address to, uint256 amount) external {
        require(allowedMinters[msg.sender], "only allowed minters can mint rewards");
        _mint(to, amount);
    }

    function addMinter(address newMinterAdd) external onlyOwner {
        allowedMinters[newMinterAdd] = true;
    }

    function removeMinter(address minterAdd) external onlyOwner {
        allowedMinters[minterAdd] = false;
    }
}
