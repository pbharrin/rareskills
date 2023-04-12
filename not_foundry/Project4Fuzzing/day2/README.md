## No solution could be found

I tried many settings and running over 1B solutions on this.  After learning an alytical solution I think is highly unlikely two random numbers would be chosen to satisfy the contraints needed to break the invariant.  (One random number for the value sent and one for the amount of tokens to buy.)

### Analytical solution.  
The analytical solution takes advantage of unchecked overflow in ```buy()```.  You could send a small amount of ether to buy() and receive many tokens.  