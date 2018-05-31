pragma solidity ^0.4.11;

contract Owned {
  address public owner;
  function Owned() public { owner = msg.sender; }
  modifier onlyOwner { require(msg.sender == owner); _; }
}

// exercise 10.5
contract Mortal is Owned {
  event Destructed();
  function kill() public onlyOwner { emit Destructed(); selfdestruct(owner); }
}
contract CircuitBreaker is Owned {
  bool public stopped;
  event Stopped(bool stopped);
  function CircuitBreaker() public { stopped = false; }
  modifier notStopped() {
    if(stopped) revert(); else _;
  }
  function toggleCircuit(bool _stopped) public onlyOwner {
    stopped = _stopped; emit Stopped(stopped);
  }
}

contract Timeout {
  uint public deadline;// UnixTime
  bool private _timeout;
  mapping (bool => string) private _status;

  function Timeout(uint _duration, string _inTimeStatus, string _outOfTimeStatus) public {
    deadline = now + _duration;
    _status[false] = _inTimeStatus;
    _status[true] = _outOfTimeStatus;
    _timeout = false;
  }

  event Status(string status);

  function checkDeadline() private {// just check the status
    if(now >= deadline) _timeout = true;
  }
  function status() public {// show the status on the event
    checkDeadline(); emit Status(_status[_timeout]);
  }

  modifier inTime() {
    checkDeadline(); if(_timeout) revert(); else _;
  }
  modifier outOfTime() {
    checkDeadline(); if(!_timeout) revert(); else _;
  }

}


contract Auction is Mortal, CircuitBreaker, Timeout {

  // exercise 10.5
  // keep bidder info for refunding
  struct Bidder {
    address addr;
    uint amount;
    bool refunded;
  }
  Bidder public highestBidder;
  uint public numBidders;
  mapping (uint => Bidder) public bidders;


  function Auction() public Timeout(100, "Bidding...", "Closed") {
  //function Auction(uint _duration) public Timeout(_duration, "Bidding...", "Closed") {
    highestBidder.addr = msg.sender;
    highestBidder.amount = 0;

    // exercise 10.5
    owner = msg.sender;
    numBidders = 0;
  }

  function bid() public payable inTime notStopped {
    require(msg.value > highestBidder.amount);

    // for refunding
    Bidder storage _bidder = bidders[numBidders++];
    _bidder.addr = highestBidder.addr;
    _bidder.amount = highestBidder.amount;
    _bidder.refunded = false;

    // update
    highestBidder.addr = msg.sender;
    highestBidder.amount = msg.value;

    emit Bid(numBidders, highestBidder.addr, highestBidder.amount);
  }
  event Bid(uint _num, address _addr, uint _amount);


  // onlyOwner

  event Addr(address _addr);
  event Uint(uint _uint);
  event Bool(bool _bool);

  function close() public onlyOwner notStopped {
    if(!owner.send(highestBidder.amount)) revert(); // for owner
    for(uint i = 1; i < numBidders; i++) {          // for bidders
      _refund(i);
    }
    emit Close(highestBidder.addr, highestBidder.amount);
  }
  event Close(address addr, uint amount);

  function _refund(uint i) private onlyOwner notStopped {
    if(!bidders[i].refunded) {
      //emit Bool(!bidders[i].addr.send(bidders[i].amount));
      //if(!bidders[i].addr.send(bidders[i].amount)) revert();
      bidders[i].refunded = true;
    }
    emit Refund(i, bidders[i].addr, bidders[i].amount);
  }
  event Refund(uint i, address addr, uint amount);
}

