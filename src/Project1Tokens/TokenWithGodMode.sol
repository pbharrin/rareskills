// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC1363, ERC20} from "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";

contract TokenWithGodMode is ERC1363 {
    address private _admin;

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) ERC20(_name, _symbol) {
        // set initial supply, and admin
        _mint(msg.sender, _initialSupply);
        _admin = msg.sender;
    }

    /**
     * adminTransfer allows the admin to use God mode.
     */
    function adminTransfer(address from, address to, uint256 amount) public returns (bool) {
        // make sure sender is admin
        require(msg.sender == _admin, "Only the token admin can use God mode.");
        _transfer(from, to, amount);
        return true;
    }
}
