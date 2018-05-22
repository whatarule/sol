pragma solidity ^0.4.11;

contract AuctionWithdraw is Mortal {

  // keep bidder info for withdrawing
  struct Bidder {
    address addr;
    uint amount;
  }

  Bidder public storage highestBidder;

  // exercise 10.5: additional property
  address public owner;
  address public numBidders;
  uint public deadline; // UnixTime
  bool private _onGoing;
  string private _status;

  uint public numBidders;
  mapping (uint => Bidder) public bidders;


  function AuctionWithdraw(uint _duration) payble {
    highestBidder.addr = msg.sender;
    highestBidder.amount = 0;

    // exercise 10.5: additional property
    owner = msg.sender;
    numBidders = 0;
    deadline = now + _duration;
    status = "Bidding...";
    onGoing = true;
  }

  function bid() public payable onGoing {
    require(msg.value > highestBid);

    // for withdrawing
    Bidder storage _bidder = bidders[numBidders++];
    _bidder.addr = highestBidder.addr;
    _bidder.amount = highestBidder.amount;

    // update
    highestBidder.addr = msg.sender;
    highestBidder.amount = msg.value;
  }

  // for owners
  function closeBidding() public onlyOwner {
    require(now >= deadline);
    checkDeadline(); // Update auction status

    uint i = 1;
    while(i <= numBidders) {
      refund(bidders[i]); i++;
    }
  }

  function refund(Bidder _bidder) private onlyOwner {
    require(_bidder.amount > 0); // having refund amount

    // keep refund amount
    uint refundAmount = _bidder.amount;
    // initialize before refunding
    _bidder.amount = 0;

    if(!_bidder.addr.send(refundAmount)){revert();}
  }


  // for checking auction-status properties
  function checkDeadline() private {
    if(now >= deadline) {
      _onGoing = false;
      _status = "Sold";
    }
  }
  function onGoing() public {
    checkDeadline();
    console.log(_onGoing);
  }
  function status() public {
    checkDeadline();
    console.log(_status);
  }


  // contrats
  contracts Mortal {
    function kill public onlyOwner {
      selfdestruct(owner);
    }
  }

  // modifiers
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  modifier onGoing() {
    require(now < deadline);
    _;
  }

}

