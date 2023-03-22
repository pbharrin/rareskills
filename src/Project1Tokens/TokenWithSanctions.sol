// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC1363, ERC20, IERC20} from "erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";

contract TokenWithSanctions is ERC1363 {
    mapping(address => bool) private _isBanned;
    address private _admin;

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) ERC20(_name, _symbol) {
        // set initial supply, and admin
        _mint(msg.sender, _initialSupply);
        _admin = msg.sender;
    }

    /**
     * Sanctions an address from any trading.  After this is set no sending or
     * receiving will be allowed to/from this address.
     */
    function banAddress(address addr) public returns (bool) {
        require(msg.sender == _admin, "Only the token admin can ban addresses.");
        _isBanned[addr] = true;
        return true;
    }

    /**
     * Remove sanctions from an address.
     */
    function unBanAddress(address addr) public returns (bool) {
        require(msg.sender == _admin, "Only the token admin can un-ban addresses.");
        _isBanned[addr] = false;
        return true;
    }

    /**
     * Checks the sanctioned status of an address.
     */
    function status(address addr) public view returns (bool) {
        return _isBanned[addr];
    }

    /**
     * Checks the sanctoned status of any to/from address before any transfer.
     */
    function _beforeTokenTransfer(address from, address to, uint256) internal view override {
        require(!_isBanned[from] && !_isBanned[to], "Sorry the to or from addresses are banned.");
    }

    // override the transfer function
    // function transfer(address to, uint256 amount) public virtual override(ERC20, IERC20) returns (bool) {
    //     address owner = _msgSender();
    //     require(!_isBanned[owner] && !_isBanned[to], "Sorry the to or from addresses are banned.");
    //     _transfer(owner, to, amount);
    //     return true;
    // }
}
