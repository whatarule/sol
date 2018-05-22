pragma solidity ^0.4.11;

contract Auction is Mortal, CircuitBreaker, TimeLimited {

  // keep bidder info for withdrawing
  struct Bidder {
    address addr;
    uint amount;
  }

  Bidder public storage highestBidder;

  uint public numBidders;
  mapping (uint => Bidder) public bidders;


  function Auction(uint _duration) payable TimeLimited(_duration, "Bidding...", "Closed") {
    highestBidder.addr = msg.sender;
    highestBidder.amount = 0;

    // exercise 10.5: additional property
    owner = msg.sender;
    numBidders = 0;
  }

  function bid() public payable onGoing {
    require(msg.value > highestBid);

    // for refunding
    Bidder storage _bidder = bidders[numBidders++];
    _bidder.addr = highestBidder.addr;
    _bidder.amount = highestBidder.amount;

    // update
    highestBidder.addr = msg.sender;
    highestBidder.amount = msg.value;
  }


  // onlyOwner

  function close() public onlyOwner timeout {
    msg.sender.send(highestBidder.amount){revert();}

    // for other bidders
    uint i = 1; while(i <= numBidders) {
      refund(bidders[i]); i++;
    }

    // Update auction status
    checkDeadline();
  }

  function refund(Bidder _bidder) private onlyOwner closed {
    require(_bidder.amount > 0); // having refund amount

    // keep refund amount
    uint refundAmount = _bidder.amount;
    // initialize before refunding
    _bidder.amount = 0;

    if(!_bidder.addr.send(refundAmount)){revert();}
  }



  // contrats
  contract Owned {
    address public owner;
    modifier Owned() public {
      owner = msg.sender;
    }
  }

  contract Mortal is Owned{
    function kill public onlyOwner {
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

    function TimeLimited(uint _duration, string _onGoingStatus, string _closedStatus) {
      deadline = now + _duration;
      onGoingStatus = _onGoingStatus;
      closedStatus = _closedStatus;
      _status = _onGoingStatus;
      _onGoing = true;
    }

    modifier onGoing() {
      require(now < deadline); _;
    }
    modifier timeout() {
      require(now >= deadline); _;
    }

    // for checking status properties
    function checkDeadline() private {
      if(now >= deadline) {
        _onGoing = false; _status = closedStatus;
      }
    }
    function onGoing() public {
      checkDeadline(); console.log(_onGoing);
    }
    function status() public {
      checkDeadline(); console.log(_status);
    }

  }

}

