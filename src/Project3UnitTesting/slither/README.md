
# Slither Results

The following are not false positives. There were false positives with test scripts.
dangerous-strict-equalities produced many false positives.  

##  reentrancy-vulnerabilities

The Token with bonding curve sell was calling _burn() before updating all the state variables.  

## contracts-that-lock-ether

The enumerable token was locking funds, a withdraw function was added.  

## reentrancy-vulnerabilities-1

The vault contact had a vulnerability in stake() and collectRewards().  

## local-variable-shadowing

A number of token contracts had variables that shadowed ERC20 token variables such as: _name, _symbol, totalSupply.  The variable owner shadowed a variable from Ownable.  

## block-timestamp

Staking rewards was using the block.timestamp to calculate rewards.  It is stated that this could
be manipulated by miners and that a better idea would be to use block.number.  With block.number, 
the time can be estimated by the average number of blocks per day.  On the Ethereum maninnet this is
around 7110 blocks/day.  This was corrected in the Vault contract.  

## incorrect-versions-of-solidity

Many contracts specified 0.8.13 when 0.8.18 was the latest, this was updated.  

## state-variables-that-could-be-declared-immutable

Many contracts had variables that were only modified in the constructor that could be specified as 
immutable.

# MythX Results

Errors from MythX:

### Error 1: State variable visibility is not set

```Java
LOW
SWC-108
State variable visibility is not set.
It is best practice to set the visibility of state variables explicitly. The default visibility for "owner" is internal. Other possible visibility settings are public and private.

Source file
src/Project2NFTs/part3/NFTEnumerable.sol

uint256 public constant MAX_SUPPLY = 20;
uint256 public constant PRICE = 1 ether;
address owner;
constructor() ERC721("Enumer", "ENUM") {
```

This error also appeared in: ```src/Project2NFTs/part3/PrimeChecker.sol`` three times, and ```src/Project2NFTs/part2/Vault.sol``` five times.  

### Error 2: Requirement violation.

```Java
Requirement violation.
A requirement was violated in a nested call and the call was reverted as a result. Make sure valid inputs are provided to the nested call (for instance, via passed arguments).

Source file
lib/erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol

try IERC1363Spender(spender).onApprovalReceived(_msgSender(), amount, data) returns (bytes4 retval) {
return retval == IERC1363Spender.onApprovalReceived.selector;
} catch (bytes memory reason) {
```

I am unclear about this error.  

### Error 3: Potential use of "block.number" as source of randonmness.

>The relevant parts of the warning are: The environment variable "block.number" looks like it might be used as a source of randomness. Note that the values of variables like coinbase, gaslimit, block number and timestamp are predictable and can be manipulated by a malicious miner.

This appears in: ```src/Project2NFTs/part2/Vault.sol```.  I do not think this is a potential problem or will cause problems with the desired application: minting rewards.  

