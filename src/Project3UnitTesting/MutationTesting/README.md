# Mutation testing with Vertigo_rs

Errors uncovered by Vertigo:
48 mutations 20/48 were killed.  



```bash
[+] Survivors
Mutation:
    File: /Users/pbharrin/Documents/GitHub/rareskills/src/Project2NFTs/part2/Token.sol
    Line nr: 22
    Result: Lived
    Original line:
             function addMinter(address newMinterAdd) external onlyOwner {

    Mutated line:
             function addMinter(address newMinterAdd) external  {

Mutation:
    File: /Users/pbharrin/Documents/GitHub/rareskills/src/Project2NFTs/part2/Token.sol
    Line nr: 26
    Result: Lived
    Original line:
             function removeMinter(address minterAdd) external onlyOwner {

    Mutated line:
             function removeMinter(address minterAdd) external  {
```

Both of the mutations had to do with onlyOwner.  When the onlyOwner modifier was removed the functions still passed the tests.  This makes sense as onlyOwner will make a function more restrictive, so when it is removed more can be done.  