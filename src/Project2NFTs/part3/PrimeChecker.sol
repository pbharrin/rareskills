// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {NFTEnumerable} from "./NFTEnumerable.sol";

contract PrimeChecker {
    NFTEnumerable _collection; // Ref to our NFT contract

    uint256[8] public primes20 = [2, 3, 5, 7, 11, 13, 17, 19];
    mapping(uint256 => bool) private primes;

    constructor(NFTEnumerable collection) {
        _collection = collection;

        // populate prime map
        for (uint256 i = 0; i < primes20.length; i++) {
            primes[primes20[i]] = true;
        }
    }

    /**
     * Simple mapping lookup of primes in range [1, 20].
     */
    function _isPrime(uint256 candidate) private view returns (bool) {
        return primes[candidate];
    }

    /**
     * Function to count the number of prime tokenIDs owned by an address and return the count.
     */
    function numberOfPrimes(address nftOwner) public view returns (uint256) {
        // get the number of tokens owned
        uint256 numTokensOwned = _collection.balanceOf(nftOwner);

        uint256 primeCount = 0;

        // iterate over the tokens, check if they are prime and if so increment counter.
        for (uint256 i = 0; i < numTokensOwned; i++) {
            if (_isPrime(_collection.tokenOfOwnerByIndex(nftOwner, i))) {
                primeCount++;
            }
        }

        return primeCount;
    }
}
