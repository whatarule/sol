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

// exercise 10.5
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
  bool private _onGoing;
  mapping (bool => string) private _status;

  function TimeLimited(uint _duration, string _onGoingStatus, string _closedStatus) public {
    deadline = now + _duration;
    _onGoing = true;
    _status[true] = _onGoingStatus;
    _status[false] = _closedStatus;
  }

  modifier onGoing() {
    checkDeadline(); require(_onGoing); _;
  }
  modifier timeout() {
    checkDeadline(); require(!_onGoing); _;
  }

  event status(string _status);

  // for checking status properties
  function checkDeadline() private {
    if(now >= deadline) { _onGoing = false; }
  }
  function checkStatus() public returns(string) {
    checkDeadline();
    emit status(_status[_onGoing]);
    return _status[_onGoing];
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

  function close() public payable onlyOwner timeout isStopped {
    uint i = 1; while(i <= numBidders) {
      refund(bidders[i]); i++;
    }
  }

  function refund(Bidder _bidder) public payable onlyOwner timeout isStopped {
    require(_bidder.amount > 0); // having refund amount

    // keep refund amount
    uint refundAmount = _bidder.amount;
    // initialize before refunding
    _bidder.amount = 0;

    if(!_bidder.addr.send(refundAmount)){revert();}
  }
}

