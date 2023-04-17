# Day 1 Solution Write-ups

### Hello Ethernaut
Here you need to get the password which is stored in ```contract.password()``` then you can enter it into the method ```contract.authenticate()```.  


### Fallback

There are two ways to become the owner of this contact: 1. send more than 1000 Eth to the contract or 2. use the fallback function.  The fallback is triggered when ether is sent to the contract with specifying a function to call.  You can send eth in JS using: 
```Javascript
web3.eth.sendTransaction({from:eth.coinbase,to:contract.address, value:100})
```

### Fallout

There is no receive function in this contract so sending ether to the contract will trigger the constructor which assigns the owner to msg.sender.  

### Telephone

The objective here is to claim ownership of the contract.  This contract has a method that will assign the owner: 
```Java
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
```
This takes advange of differences between tx.origin and msg.sender.  If we create a new contract and have that call this method then tx.origin will not be equal to msg.sender and we can control of ownership.  

```Java
contract TelephoneForwarder {

  address public owner;
  // Mumbai 
  address constant ENDPOINT = 0xE2e327fca9B715D8595399863C86AA85aAC81414;

  constructor() {}

  function changeOwner(address _owner) public {
      Telephone telly = Telephone(ENDPOINT);
      telly.changeOwner(_owner);
  }

}
```

### Capture The Ether Guess the Number

The objective is to drain the contract, and the constructor requires 1 ETH.  This function will return 2 ETH if the number is guessed correctly.  However each guess costs 1 ETH.  To drain the contract you need to enter the correct value (42).  