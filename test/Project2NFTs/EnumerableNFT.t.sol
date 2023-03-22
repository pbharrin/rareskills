// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NFTEnumerable} from "../../src/Project2NFTs/part3/NFTEnumerable.sol";
import {PrimeChecker} from "../../src/Project2NFTs/part3/PrimeChecker.sol";

contract NFTEnumerableTest is Test {
    NFTEnumerable public collection;
    PrimeChecker public primeChecker;

    address constant DEFAULT_ADD = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
    address add2;

    function setUp() public {
        // NFT contract need to be deployed before the prime checker
        collection = new NFTEnumerable();
        primeChecker = new PrimeChecker(collection);

        add2 = vm.addr(2);
    }

    // test the number of primes in the first 3 NFTs
    function testFirst3Primes() public {
        uint256 num2add = 3;
        collection.massFreeMint(num2add);
        assert(num2add == collection.balanceOf(DEFAULT_ADD));

        // there are 2 primes in [1,3]
        assert(primeChecker.numberOfPrimes(DEFAULT_ADD) == 2);
    }

    // test the number of primes in the first 20 NFTs
    function testAll20Primes() public {
        uint256 num2add = 20;
        collection.massFreeMint(num2add);
        assert(num2add == collection.balanceOf(DEFAULT_ADD));
        assert(primeChecker.numberOfPrimes(DEFAULT_ADD) == 8);
    }

    // test the number of primes in the first 20 NFTs
    function testMultipleOwners() public {
        uint256 num2add = 10;
        collection.massFreeMint(num2add);
        assert(num2add == collection.balanceOf(DEFAULT_ADD));
        assert(primeChecker.numberOfPrimes(DEFAULT_ADD) == 4);

        vm.deal(add2, 3 ether); // give add2 funds for gas
        vm.startPrank(add2);
        collection.massFreeMint(num2add);
        assert(num2add == collection.balanceOf(add2));
        assert(primeChecker.numberOfPrimes(add2) == 4);
        vm.stopPrank();
    }
}
