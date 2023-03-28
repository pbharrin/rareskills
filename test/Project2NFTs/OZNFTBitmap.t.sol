// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import "../../src/Project2NFTs/part1/OZNFTBitmap.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OZNFTBitmapTest is Test {
    using ECDSA for bytes32;

    OZNFTBitmap public bitmapNFT;
    // address constant signerPK = 0x4cdB91f21E7cf8a48CeAA4998aeeEB368f7808E5;  //public key
    uint256 privateKey;
    address add2;
    uint256 constant RSV_SIG_LEN = 65;

    function setUp() public {
        add2 = vm.addr(2);
        privateKey = vm.envUint("PRIVATE_KEY"); // get from .env file
        bitmapNFT = new OZNFTBitmap();
        bitmapNFT.setAllowList2SigningAddress(vm.addr(privateKey));
    }

    function signTokenNum(uint256 ticketNum, address adin) private view returns (bytes memory) {
        // create digest:   keccak256 gives us the first 32bytes after doing the hash
        // so this is always 32 bytes.
        bytes32 digest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", bytes32(uint256(uint160(adin))), bytes32(ticketNum))
        );

        // r and s are the outputs of the ECDSA signature
        // r,s and v are packed into the signature.  It should be 65 bytes: 32 + 32 + 1
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        // pack v, r, s into 65bytes signature
        // bytes memory signature = abi.encodePacked(r, s, v);
        return abi.encodePacked(r, s, v);
    }

    /**
     * Modified code from SO, this can be used for any length of bytes with a 2 modifications.
     */
    function bytes65ToString(bytes memory _bytes) public pure returns (string memory) {
        // bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(132); // 2 + 65 * 2
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 65; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i] & 0x0f)];
        }
        return string(_string);
    }

    /**
     * Sign some addresses to use externally.
     */
    function testExternalPrep() public view {
        console.log("signerAdd: (set this after deploy) %s", vm.addr(privateKey));

        address remixAdd = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        console.log("remixAdd: %s", remixAdd);

        uint256 tokenNum = 0;
        bytes memory signature = signTokenNum(tokenNum, remixAdd);
        console.log("remixAdd signed for %d: %s", tokenNum, bytes65ToString(signature));
        tokenNum = 1;
        signature = signTokenNum(tokenNum, remixAdd);
        console.log("remixAdd signed for %d: %s", tokenNum, bytes65ToString(signature));
    }

    /**
     * Test presale with the mapping checking if a token was taken.
     */
    function testPresale() public {
        bytes memory signature = signTokenNum(0, add2);
        assert(signature.length == RSV_SIG_LEN);

        // switch to address 2 and do presale
        vm.deal(add2, 10 ether);
        vm.startPrank(add2);
        bitmapNFT.presale{value: 1 ether}(0, signature, false);

        // try to reuse ticket
        vm.expectRevert("You have already done presale");
        bitmapNFT.presale{value: 1 ether}(0, signature, false);

        // try another presale
        vm.expectRevert("verify signature failed");
        bitmapNFT.presale{value: 1 ether}(1, signature, false);
        vm.stopPrank();

        signature = signTokenNum(1, address(this));
        vm.expectRevert("the presale price is not correct");
        bitmapNFT.presale{value: 0.69 ether}(1, signature, false);
    }

    function testMint() public {
        vm.expectRevert("the price is not correct");
        bitmapNFT.mint();

        bitmapNFT.mint{value: 2 ether}();
        assert(bitmapNFT.balanceOf(address(this)) == 1);

        for (uint256 i = 1; i < bitmapNFT.MAX_SUPPLY(); ++i) {
            bitmapNFT.mint{value: 2 ether}();
        }

        vm.expectRevert("The MAX_SUPPLY has been reached");
        bitmapNFT.mint{value: 2 ether}();

        bytes memory signature = signTokenNum(11, address(this));
        vm.expectRevert("Token supply exceeds max.");
        bitmapNFT.presale{value: 1 ether}(11, signature, false);
    }

    function testSetAllowListSigner() public {
        vm.expectRevert("The zero address cannot sign messages.");
        bitmapNFT.setAllowList2SigningAddress(address(0));

        bitmapNFT.setAllowList2SigningAddress(add2);

        vm.startPrank(add2);
        vm.expectRevert("Ownable: caller is not the owner");
        bitmapNFT.setAllowList2SigningAddress(add2);
        vm.stopPrank();
    }

    /**
     * Test presale with the bitmap checking if a token was taken.
     */
    function testPresaleBM() public {
        bytes memory signature = signTokenNum(0, add2);
        assert(signature.length == RSV_SIG_LEN);

        // switch to address 2 and do presale
        vm.deal(add2, 10 ether);
        vm.startPrank(add2);
        bitmapNFT.presale{value: 1 ether}(0, signature, true);

        // try another presale
        vm.expectRevert("verify signature failed");
        bitmapNFT.presale{value: 1 ether}(1, signature, true);
        vm.stopPrank();
    }

    function testRenounce() public {
        vm.expectRevert("cannot renounce ownership");
        bitmapNFT.renounceOwnership();
    }

    function testTransfer() public {
        vm.expectRevert("cannot transfer ownership");
        bitmapNFT.transferOwnership(add2);
    }

    function testClaimErrors() public {
        bytes memory signature = signTokenNum(300, add2);
        assert(signature.length == RSV_SIG_LEN);

        // switch to address 2 and do presale
        vm.deal(add2, 10 ether);
        vm.startPrank(add2);
        vm.expectRevert("ticket size too large");
        bitmapNFT.presale{value: 1 ether}(300, signature, true);
        vm.stopPrank();
    }

    function testBMClaimTwice() public {
        bytes memory signature = signTokenNum(3, add2);
        vm.deal(add2, 10 ether);
        vm.startPrank(add2);
        bitmapNFT.presale{value: 1 ether}(3, signature, true);
        vm.expectRevert("this ticket has been claimed");
        bitmapNFT.presale{value: 1 ether}(3, signature, true);
        vm.stopPrank();
    }

    /**
     * Make sure the owner can withdraw funds.
     */
    function testWithDraw() public {
        bitmapNFT.mint{value: 2 ether}();
        bitmapNFT.mint{value: 2 ether}();

        uint256 contactBalanceBefore = address(bitmapNFT).balance;
        uint256 balanceBeforeWithdraw = address(this).balance;
        bitmapNFT.withdraw();
        uint256 balanceAfterWithdraw = address(this).balance;
        assert(contactBalanceBefore == balanceAfterWithdraw - balanceBeforeWithdraw);
    }

    function testBaseURI() public {
        bitmapNFT.mint{value: 2 ether}();
        bytes32 lhs = keccak256(abi.encode(bitmapNFT.tokenURI(0)));
        bytes32 rhs = keccak256(abi.encode("ipfs://QmQwFXwFDoagfQ5VVWeBzyaBm2DhoBZzVX2P9wPK27nqkp/0"));
        assert(lhs == rhs);
    }

    receive() external payable {
        console.log("the contract receive was called");
    }
}
