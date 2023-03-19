// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";


contract OZNFTBitmap is ERC721, Ownable, ERC2981 {
    using ECDSA for bytes32;
    using BitMaps for BitMaps.BitMap;

    uint256 public tokenSupply = 0;  // amount of NFTs currently minted
    uint256 public constant MAX_SUPPLY = 10;
    uint256 public constant PRICE = 2 ether;
    uint256 public constant PRICE_PRE = 1 ether;

    uint256 private constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant BITMAP_MAX_SIZE = 256;
    BitMaps.BitMap private bitmap;

    // uint256[3] arr = [MAX_INT, MAX_INT, MAX_INT];
    // This should be set after the contract is deployed.
    address public allowListSigningAddress = address(1337);

    mapping(uint256 => uint256) ticketsHaveBeenMinted;

    constructor() ERC721("MySweetNFT", "MSNT"){
        _setDefaultRoyalty(msg.sender, 250);  // sets royalty to 2.5%
        // initialze bitmap to all 1s, this will save gas
        bitmap._data[0] = MAX_INT;
    }

    function mint() external payable {
        require(tokenSupply < MAX_SUPPLY, "The MAX_SUPPLY has been reached");
        require(msg.value == PRICE, "the price is not correct");
        _mint(msg.sender, tokenSupply);
        tokenSupply++;
    }

    function setAllowList2SigningAddress(address _signingAddress) external {
        allowListSigningAddress = _signingAddress;
    }

    /**
    Verify by public signature. 
     */
    function verifySig(uint256 ticketNum, bytes calldata _signature) private view {
        require(
            allowListSigningAddress ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(uint256(uint160(msg.sender))),
                        bytes32(ticketNum)
                    )
                ).recover(_signature), "not allowed"
        );
    }

    /**
    Uses a mapping to claim the ticket or block transaction.   
    A user could have more than one ticket, so we don't use
    address for the mapping key, we use ticketNumber.  
     */
    function claimTicketMap(uint256 ticketNumber) private {
        require(ticketsHaveBeenMinted[ticketNumber] < 1, "You have already done presale");
        ticketsHaveBeenMinted[ticketNumber]++; 
    }

    /**
    Uses a home brew Bitmap to claim the ticket.  
     */
    // function claimTicketBM(uint256 ticketNumber) private {
    //     require(ticketNumber < arr.length * 256, "too large");
    //     uint256 storageOffset = ticketNumber / 256;
    //     uint256 offsetWithin256 = ticketNumber % 256;
    //     uint256 storedBit = (arr[storageOffset] >> offsetWithin256) & uint256(1);
    //     require(storedBit == 1, "already taken");

    //     arr[storageOffset] = arr[storageOffset] & ~(uint256(1) << offsetWithin256);
    // }

    /**
    OpenZeppelin Bitmap version of claim ticket.
     */
    function claimTicketOZBM(uint256 ticketNumber) private {
        require(ticketNumber < BITMAP_MAX_SIZE, "ticket size too large");
        require(bitmap.get(ticketNumber), "this ticket has been claimed");
        bitmap.unset(ticketNumber);
    }

    /**
    Presale function with signature of address, ticketNumber.  
    We need: 1. ticketNumber, 2. sender's address 3. signed 1+2.  
    Signature is: abi.encode(address, ticketNumber)
     */
    function presale(uint256 ticketNumber, bytes calldata signature, bool useBM) external payable returns (uint256) {
        require(tokenSupply < MAX_SUPPLY, "Token supply exceeds max.");
        require(msg.value == PRICE_PRE, "the presale price is not correct");

        // Check if user can do a purchase and has not done one yet.
        verifySig(ticketNumber, signature);
        useBM ? claimTicketOZBM(ticketNumber) : claimTicketMap(ticketNumber);

        _mint(msg.sender, tokenSupply);
        tokenSupply++;
        return msg.value;
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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}