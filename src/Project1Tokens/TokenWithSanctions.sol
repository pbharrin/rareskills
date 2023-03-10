// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC777/ERC777.sol";
import "https://github.com/vittominacori/erc1363-payable-token/blob/v4.8.2/contracts/token/ERC1363/ERC1363.sol";

contract TokenWithSanctions is ERC777{
    uint256 dog = 10;
}