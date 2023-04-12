# Solution


```Java
approve(0x20000, <reallly large number>) from 0x30000
-> now 0x20_000 can spend a lot of 0x30_000s tokens
tranferFrom(0x30000,0x1ffffe, 755) from 0x20000
-> 0x20_000 transfers a little to 0x1ffffe, but _transfer underflows 0x20_000's account.  transferFrom checks to and from but not msg.sender which is a 3rd address.  
transfer(0x30000, 9_999_999) from 0x20000
->  finally major cash is sent to 0x20_000 from 0x20_000 who had so much from the underflow.  
```

The exploit takes advantage of a flaw in the token's transferFrom() function, and underflow.  The transferFrom() function has three parties involved: to, from and msg.sender, however underflow is only checked on: to and from.  The function _transfer() is then called with only the "to" address, incorrectly debting from the unchecked msg.sender not the "from" address.  