pragma solidity ^0.4.11;

contract Owned {
  address public owner;
  function Owned() public { owner = msg.sender; }
  modifier onlyOwner { require(msg.sender == owner); _; }
}

// exercise 10.5
contract Mortal is Owned {
  event Destructed();
  function destruct() public onlyOwner { emit Destructed(); selfdestruct(owner); }
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

  struct Bidder {
    address addr;
    uint amount;
    bool refunded;
  }
  Bidder public highestBidder;

  // keep bidders' info for refunding
  mapping (uint => Bidder) public bidders;
  uint public numBidders;

  function setBidderInfo(address _addr, uint _amount) private inTime notStopped {
    Bidder storage _bidder = bidders[numBidders++];
    _bidder.addr = _addr;
    _bidder.amount = _amount;
    _bidder.refunded = false;
  }

  // constructor
  function Auction(uint _duration) public Timeout(_duration, "Bidding...", "Closed") {
    highestBidder.addr = msg.sender;
    highestBidder.amount = 0;
    numBidders = 0;
  }

  function bid() public payable inTime notStopped {
    require(msg.value > highestBidder.amount);

    // keep the current highestBidder's info for refunding
    setBidderInfo(highestBidder.addr, highestBidder.amount);

    // update highestBidder
    highestBidder.addr = msg.sender;
    highestBidder.amount = msg.value;

    emit Bid(numBidders, highestBidder.addr, highestBidder.amount);
  }
  event Bid(uint _num, address _addr, uint _amount);

  // onlyOwner
  function close() public onlyOwner outOfTime notStopped {
    // send back ether to the bidders
    for(uint i = 1; i < numBidders; i++) { _refund(i); }
    emit Close(highestBidder.addr, highestBidder.amount);
    // send remains to the owner
    destruct();
  }
  event Close(address addr, uint amount);

  function _refund(uint i) private onlyOwner outOfTime notStopped {
    // check not having been refunded yet
    if(!bidders[i].refunded) {
      if(!bidders[i].addr.send(bidders[i].amount)) revert();
      bidders[i].refunded = true;
    }
    emit Refund(i, bidders[i].addr, bidders[i].amount);
  }
  event Refund(uint i, address addr, uint amount);
}

