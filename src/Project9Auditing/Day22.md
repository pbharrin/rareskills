
## Day 22: Private Variables

### Ethernaut #8 Vault

This is a relatively simple contract.  The entirety of it is pasted here: 

```Java
ontract Vault {
  bool public locked;
  bytes32 private password;

  constructor(bytes32 _password) {
    locked = true;
    password = _password;
  }

  function unlock(bytes32 _password) public {
    if (password == _password) {
      locked = false;
    }
  }
}
```

We can unlock this by reading the private variable ```password```.  Any part of a contract can be read as all the information on the blockchain is public.  We just need a few pieces of information to locate the password.  Each slot is 32 bytes.  The first slot will only contain one byte as it is a bool.  The second slot (slot 1) will contain the 32 byte password.  We can use the following Javascript in the console to get the bytes stored at slot 1.  

```Javascript
pass = await web3.eth.getStorageAt(addr, 1, console.log)
```

Here the variable ```addr``` is the address of the contract.  This password was then submitted to unlock the contract.  