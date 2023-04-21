
## Day 8

### Ethernaut #5 Token

The goal of this level is to hack a token, we start with 20 and would like to get as many as possible.  One thing to note is that the contract is written in Solidity 0.6.0, and does not include OZ SafeMath.  There are subtraction and addition operations in the transfer function.  

```Java
  function transfer(address _to, uint _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
  }
```

One thing to note here is that the require statement is vunerable to underflow.  A uint is always positive or zero so this statement will always be true.  No contract is needed to do this.  You simply need to transfer more than 20 tokens (the starting amount) and you will underflow and have a large balance.  


### Capture the Ether Token Whale Challenge

This was a challenge from Day 1 of our Fuzzing project.  The challenge starts off with only 1,000 tokens minted and 1,0000 given to the player.  This comes down to some sloppy coding.  The ```transferFrom()``` method is public and calls ```_transfer()```, often token contracts expose ```transfer()``` and then call an internal ```_transferFrom()```.  Here is the code that is problematic.  


```Java
    function approve(address spender, uint256 value) public {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    function _transfer(address to, uint256 value) internal {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public {
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        require(allowance[from][msg.sender] >= value);

        allowance[from][msg.sender] -= value;
        _transfer(to, value);
    }

```

One thing to note is that ```balanceOf[msg.sender]``` is never checked in ```_transfer()```.  
Another thing to note is that approve() has no checks, so you can approve more tokens than you currently own.  

Here is a sequence of transactions to accomplish the task.  
```Java
approve(2nd_ADDRESS, <reallly large number>) from ATTACK_ADDRESS
// now 0x20_000 can spend a lot of 0x30_000s tokens
tranferFrom(0x30000, 3RD_ADDRESS, 755) from 2nd_ADDRESS
// 2nd_ADDRESS transfers a little to 3RD_ADDRESS, but _transfer underflows 2nd_ADDRESS's account, 
// because 2nd_ADDRESS had a balance of 0.   
// transferFrom checks to and from but not msg.sender which is a 3rd address.  
transfer(ATTACK_ADDRESS, 9_999_999) from 2nd_ADDRESS
// finally major cash is sent to ATTACK_ADDRESS from 2nd_ADDRESS who had so much from the underflow.  
```

A few things could be done to improve this.  

- check the balanceOf in approve()
- in _transfer() check allowance and balanceOf to prevent over/underflow.  


### Capture the Ether Token Sale

This contract allows you to buy and sell tokens at 1 ETH, and the contract start with a balance of 1 ETH.  The objective is to take away some of the ETH stored in the contract.  

The first thing to note is that this is Solidity 0.4.21 and no SafeMath library is used, so we can look for a possible over/underflow exploit. The ```buy()``` method has an overflow vunerability.   

```Java
    function buy(uint256 numTokens) public payable {
        require(msg.value == numTokens * PRICE_PER_TOKEN);

        balanceOf[msg.sender] += numTokens;
    }
```

You are sending two pieces of information with a buy() transaction: 1. the numTokens to buy and the msg.value.  These can be consistent in two areas: normal and overflow.   The normal region is not an exploit, so we should find the overflow.  PRICE_PER_TOKEN is defined as $10^{18}$.  To overflow uint256 we need a product that will be more than the uint256 max.  $(2^{256} - 1)/10^{18) = 1.15792*10^59$.  This is roughly the amount of tokens we will get when we cause overflow, we can then use the extra tokens to sell back to the contract and extract extra ETH.  Now we need to figure out exactly how much ETH to send with this.  We can represent factions in uint256 so we need to round our answer up to the nearest whole number, this gives us: 115792089237316195423570985008687907853269984665640564039458, this is the smallest number we can have for numTokens to cause overflow.  This will give us 
We need to take the modulous of $2^256-1$ of this number to give us the amount of ETH to send in, in equation form this is: $mod((ceil((2^{256} - 1) / 10^{18} ) * 10^{18}) , (2^{256} -1))$, which yeilds a value of 415992086870360065 wei or 0.415992086870360065 ETH.  