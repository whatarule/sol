pragma solidity ^0.4.11;

contract Owned {
  address public owner;
  function Owned() public {
    owner = msg.sender;
  }
  modifier onlyOwner {
    require(msg.sender == owner); _;
  }
}

contract Mortal is Owned{
  function kill() public onlyOwner {
    selfdestruct(owner);
  }
}
contract CircuitBreaker is Owned {
  bool public stopped;
  function CircuitBreaker() public {
    stopped = false;
  }
  modifier isStopped() {
    require(!stopped); _;
  }
  function toggleCircuit(bool _stopped) public onlyOwner {
    stopped = _stopped;
  }
}

contract TimeLimited {
  uint public deadline; // UnixTime
  string public onGoingStatus;
  string public closedStatus;

  bool private _onGoing;
  string private _status;

  function TimeLimited(uint _duration, string _onGoingStatus, string _closedStatus) public {
    deadline = now + _duration;
    onGoingStatus = _onGoingStatus;
    closedStatus = _closedStatus;
    _onGoing = true;
    _status = onGoingStatus;
  }

  event currentStatus(bool _onGoing, string _status);

  modifier onGoing() {
    checkDeadline(); require(_onGoing); _;
  }
  modifier timeout() {
    checkDeadline(); require(!_onGoing); _;
  }

  // for checking status properties
  function checkDeadline() internal {
    if(now >= deadline) {
      _onGoing = false; _status = closedStatus;
    }
  }
  function checkStatus() public {
    checkDeadline(); emit currentStatus(_onGoing, _status);
  }
}


contract Auction is Mortal, CircuitBreaker, TimeLimited {

  // exercise 10.5
  // keep bidder info for refunding
  struct Bidder {
    address addr;
    uint amount;
  }
  Bidder public highestBidder;
  uint public numBidders;
  mapping (uint => Bidder) public bidders;


  function Auction(uint _duration) payable public TimeLimited(_duration, "Bidding...", "Closed") {
    highestBidder.addr = msg.sender;
    highestBidder.amount = 0;

    // exercise 10.5
    owner = msg.sender;
    numBidders = 0;
  }

  function bid() public payable onGoing isStopped {
    require(msg.value > highestBidder.amount);

    // for refunding
    Bidder storage _bidder = bidders[numBidders++];
    _bidder.addr = highestBidder.addr;
    _bidder.amount = highestBidder.amount;

    // update
    highestBidder.addr = msg.sender;
    highestBidder.amount = msg.value;
  }


  // onlyOwner

  function close() public onlyOwner timeout isStopped {
    if(!msg.sender.send(highestBidder.amount)){revert();}

    // for other bidders
    uint i = 1; while(i <= numBidders) {
      refund(bidders[i]); i++;
    }
  }

  function refund(Bidder _bidder) private onlyOwner timeout isStopped {
    require(_bidder.amount > 0); // having refund amount

    // keep refund amount
    uint refundAmount = _bidder.amount;
    // initialize before refunding
    _bidder.amount = 0;

    if(!_bidder.addr.send(refundAmount)){revert();}
  }
}

