// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

contract OZNFTBitmap is ERC721, Ownable, ERC2981 {
    using ECDSA for bytes32;
    using BitMaps for BitMaps.BitMap;

    uint256 public tokenSupply = 0; // amount of NFTs currently minted
    uint256 public constant MAX_SUPPLY = 10;
    uint256 public constant PRICE = 2 ether;
    uint256 public constant PRICE_PRE = 1 ether;

    uint256 private constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant BITMAP_MAX_SIZE = 256;
    BitMaps.BitMap private bitmap;

    // This should be set after the contract is deployed.
    address public allowListSigningAddress = address(1337);

    mapping(uint256 => uint256) private ticketsHaveBeenMinted;

    constructor() ERC721("MySweetNFT", "MSNT") {
        _setDefaultRoyalty(msg.sender, 250); // sets royalty to 2.5%
        // initialze bitmap to all 1s, this will save gas
        bitmap._data[0] = MAX_INT;
    }

    function mint() external payable {
        require(tokenSupply < MAX_SUPPLY, "The MAX_SUPPLY has been reached");
        require(msg.value == PRICE, "the price is not correct");
        _mint(msg.sender, tokenSupply);
        tokenSupply++;
    }

    function setAllowList2SigningAddress(address _signingAddress) external onlyOwner {
        require(_signingAddress != address(0), "The zero address cannot sign messages.");
        allowListSigningAddress = _signingAddress;
    }

    /**
     * Verify by public signature.
     */
    function verifySig(uint256 ticketNum, bytes calldata _signature) private view {
        require(
            allowListSigningAddress
                == keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32", bytes32(uint256(uint160(msg.sender))), bytes32(ticketNum)
                    )
                ).recover(_signature),
            "verify signature failed"
        );
    }

    /**
     * Uses a mapping to claim the ticket or block transaction.
     * A user could have more than one ticket, so we don't use
     * address for the mapping key, we use ticketNumber.
     */
    function claimTicketMap(uint256 ticketNumber) private {
        require(ticketsHaveBeenMinted[ticketNumber] < 1, "You have already done presale");
        ticketsHaveBeenMinted[ticketNumber] = 1;
    }

    /**
     * OpenZeppelin Bitmap version of claim ticket.
     */
    function claimTicketOZBM(uint256 ticketNumber) private {
        require(ticketNumber < BITMAP_MAX_SIZE, "ticket size too large");
        require(bitmap.get(ticketNumber), "this ticket has been claimed");
        bitmap.unset(ticketNumber);
    }

    /**
     * Presale function with signature of address, ticketNumber.
     * We need: 1. ticketNumber, 2. sender's address 3. signed 1+2.
     * Signature is: abi.encode(address, ticketNumber)
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
     * Only the owner can withdraw funds.
     */
    function withdraw() external onlyOwner {
        (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "funds cannot be sent");
    }

    function renounceOwnership() public pure override {
        require(false, "cannot renounce ownership");
    }

    function transferOwnership(address) public pure override {
        require(false, "cannot transfer ownership");
    }

    // Points to the ipfs dir with the metadata
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmQwFXwFDoagfQ5VVWeBzyaBm2DhoBZzVX2P9wPK27nqkp/";
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
