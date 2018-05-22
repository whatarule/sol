pragma solidity ^0.4.11;
contract CrowdFunding {
  struct Investor {
    address addr;
    uint amount;
  }

  address public owner;
  uint public numInvestors;
  uint public deadline; // UnixTime
  string public status;
  bool public onGoing;
  uint public goalAmount;
  uint public totalAmount;
  mapping (uint => Investor) public investors;

  uint public lowestAmount;
  uint public timeLeft = deadline - now;

  modifier onlyOwner () {
    require(msg.sender == owner);
    _;
  }

  // Constructor
  function CrowdFunding(uint _duration, uint _goalAmount, uint _lowestAmount) public {
    owner = msg.sender;
    deadline = now + _duration;
    goalAmount = _goalAmount;
    lowestAmount = _lowestAmount;

    // initial property
    status = "Funding";
    onGoing = true;
    numInvestors = 0;
    totalAmount = 0;
  }

  // Destructor
  function kill() public onlyOwner {
    selfdestruct(owner);
  }

  function fund() payable public {
    require(onGoing);
    uint shortage = goalAmount - totalAmount;
    uint _lowestAmount;
    if(shortage < lowestAmount) {
      _lowestAmount = shortage;
    } else {
      _lowestAmount = lowestAmount;
    }
    require(msg.value >= _lowestAmount);
    Investor storage inv = investors[numInvestors++];
    inv.addr = msg.sender;
    inv.amount = msg.value;
    totalAmount += inv.amount;
  }

  function checkGoalReached() public {
    require(onGoing);
    require(now >= deadline);
    if(totalAmount >= goalAmount) { // Reached
      if(!owner.send(goalAmount)) {revert();}
      status = "Suceeded!";
    } else { // Fail
      uint i = 0;
      while(i <= numInvestors) {
        Investor storage _inv = investors[i];
        if(!_inv.addr.send(_inv.amount)){revert();}
        i++;
      }
      status = "Failed...";
    }
      onGoing = false;
  }
}

