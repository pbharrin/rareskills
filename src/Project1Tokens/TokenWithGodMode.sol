// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";

uint constant INITIAL_SUPPLY = 1000;

contract TokenWithGodMode is ERC1363 {
    address private _admin;
    
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        // set initial supply
        _mint(msg.sender, INITIAL_SUPPLY);
        _admin = msg.sender;
    }

    function transfer(address from, address to, uint256 amount) public virtual returns (bool) {
        // make sure sender is admin
        require(msg.sender == _admin, "Only the token admin can use God mode.");
        _transfer(from, to, amount);
        return true;
    }
}