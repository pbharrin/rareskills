## Read-only Re-entrancy

### RareSkills Riddles: Read-only reentrancy

Users can stake Eth in ReadOnlyPool, for each ETH they stake they are minted an equal amount of LPToken.  As ETH is earned (from staking) users can get back more of ETH for thier LPToken.  The goal of the attack is to get the price of the LPToken to be 0 in two transactions or less.  The value of the LPToken can be retrevied by calling ```getVirtualPrice()```.  Initially the pool starts off with 100ETH, and we start off with 2 ETH.  The pool has also earned 1Eth of profit.  

This challenge is inspired by the Curve oracle attack.  I suspect the vunerability of this contract is in the price calculation.  Read-only reentrancy is when a read-only view function is reentred.  Usually view functions are not guarded with OZ ReentrancyGuard.  

One interesting function is ```removeLiquidity()``` from ```ReadOnlyPool```.  


```Java
    // @notice burn LPTokens and get back the original deposit of ETH + profits
    function removeLiquidity() external nonReentrant {
        uint256 numLPTokens = balanceOf(msg.sender);
        uint256 totalLPTokens = totalSupply();
        uint256 profitShare = (numLPTokens + totalLPTokens) / totalLPTokens;
        uint256 ethToReturn = originalStake[msg.sender] * profitShare;

        (bool ok, ) = msg.sender.call{value: ethToReturn}("");
        require(ok, "eth transfer failed");
        _burn(msg.sender, numLPTokens);
    }
```

Ether is returned before the tokens are burnt.  This looks like it could be a possible reentrancy attack, but there is a ReentrancyGuard from OZ used.  ```_burn()``` will also fail if there are not enough tokens. I think the most important thing to note is that ```totalSupply()``` is not updated until the ```_burn()``` has been called.  So if we do something when the funds are sent to us (using ```receive()```) then we can use an inaccurate ratio.  The contract ```VulnerableDeFiContract``` has a function we can call duing this period.  It is ```snapshotPrice()``` which just calculates the ratio and stores this in the variable ```lpTokenPrice```.  We will have our ETH back, but the amount of tokens will not have been updated.  

If we deposit 2ETH, and there is 101ETH in the pool (100 deposited + 1 earned) then there will be 103ETH in the pool when we call ```removeLiquidity()``` we will get back 2ETh * 104/102 = 2.04ETH, and the pool will have 100.96ETH.  The ```totalSupply()``` should yield 100, but it will actually yield 102 becasue ```_burn()``` has not yet been called.  So the virtual price will be 100.96/102.  This will evaluate to 0 in uint256.  