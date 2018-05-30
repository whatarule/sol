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
contract Mortal is Owned {
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

  event status(string _status);

  // for checking status properties
  function checkDeadline() public {
    if(now >= deadline) { _onGoing = false; }
  }
  function checkStatus() public returns(string) {
    checkDeadline();
    emit status(_status[_onGoing]);
    return _status[_onGoing];
  }

  modifier onGoing() {
    checkDeadline(); require(_onGoing); _;
  }
  modifier timeout() {
    checkDeadline(); require(!_onGoing); _;
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


  //function Auction(uint _duration) payable public TimeLimited(_duration, "Bidding...", "Closed") {
  function Auction() payable public TimeLimited(200, "Bidding...", "Closed") {
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

  event testUint(uint _test);
  event testAddr(address _test);

  function test() public onlyOwner isStopped {
    uint _refundAmount;
    Bidder storage _bidder = bidders[0];

    // for bidders
    for(uint i = 1; i < numBidders; i++) {
      _bidder = bidders[i];
      _refundAmount = _bidder.amount; // keep refund amount
      _bidder.amount = 0;             // initialize before refunding
      if(!_bidder.addr.send(_refundAmount)){revert();}
    }

    //for owner
    if(!owner.send(highestBidder.amount)){revert();}
  }

  function testE() private {
    emit testAddr(address(this));
  }

  //function close() public onlyOwner timeout isStopped {
  function close() public onlyOwner isStopped {
    uint _refundAmount;
    // for bidders
    uint i = 1;
    while(i < numBidders) {
      emit testUint(i);
      require(bidders[i].amount > 0); // having refund amount

      // keep refund amount
      _refundAmount = bidders[i].amount;
      // initialize before refunding
      bidders[i].amount = 0;

      if(!bidders[i].addr.send(_refundAmount)){revert();}
      i++;
    }
    //for owner
    if(!owner.send(highestBidder.amount)){revert();}
  }

  //function _refund(Bidder _bidder) private timeout isStopped {
  function _refund(uint i) public {
    Bidder storage _bidder = bidders[i];
    require(_bidder.amount > 0); // having refund amount

    // keep refund amount
    uint refundAmount = _bidder.amount;
    // initialize before refunding
    _bidder.amount = 0;

    if(!_bidder.addr.send(refundAmount)){revert();}
  }

}

