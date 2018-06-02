pragma solidity ^0.4.11;

contract Owned {
        address public owner;
        function Owned() internal { owner = msg.sender; }
        modifier onlyOwner { require(msg.sender == owner); _; }
}

contract Paid {
// for error hadling:
// paid() -> revert and send back ether
// !paid() -> error log on event
        function _paid() internal view returns(bool) {
                return msg.value > 0;
        }
}

// exercise 10.5
contract Mortal is Owned {
        event Destructed();
        function destruct() public onlyOwner { emit Destructed(); selfdestruct(owner); }
}
contract CircuitBreaker is Owned, Paid {
        bool public stopped;
        event Stopped(bool stopped);
        function CircuitBreaker() internal { stopped = false; }
        modifier notStopped() {
                if(!stopped) _;
                else { require(!_paid()); emit Stopped(stopped); }
        }
        function toggleCircuit(bool _stopped) public onlyOwner {
                stopped = _stopped; emit Toggled(stopped);
        }
        event Toggled(bool stopped);
}

contract Timeout is Paid {
        uint public deadline;// UnixTime
        mapping (bool => string) private _status;

        function Timeout(uint _duration, string _inTimeStatus, string _outOfTimeStatus) internal {
                deadline = now + _duration;
                _status[false] = _inTimeStatus;
                _status[true] = _outOfTimeStatus;
        }

        // just check the status
        function _isTimeout() private view returns(bool) {
                return now >= deadline;
        }

        // show the status on the event
        function status() public {
                emit Status(_status[_isTimeout()]);
        }
        event Status(string status);

        modifier timeout(bool _bool) {
                bool _timeout = _isTimeout();
                if(_timeout == _bool) _;
                else { require(!_paid()); emit Status(_status[_timeout]); }
        }
        modifier outOfTime() {
                bool _timeout = _isTimeout();
                if(_timeout) _;
                else { require(!_paid()); emit Status(_status[_timeout]); }
        }

}


contract Auction is Mortal, CircuitBreaker, Timeout {

        // keep bidders' info for refunding
        struct Bidder {
                address addr;
                uint amount;
                bool refunded;
        }
        Bidder public highestBidder;
        mapping (uint => Bidder) public bidders;
        uint public numBidders;

        function setBidderInfo(address _addr, uint _amount) private timeout(false) notStopped {
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

        function bid() public payable timeout(false) notStopped {
                require(msg.value > highestBidder.amount);

                // keep the current highestBidder's info for refunding
                setBidderInfo(highestBidder.addr, highestBidder.amount);

                // update highestBidder
                highestBidder.addr = msg.sender;
                highestBidder.amount = msg.value;

                emit Bid(numBidders, highestBidder.addr, highestBidder.amount);
        }
        event Bid(uint num, address addr, uint amount);

        // onlyOwner
        function close() public onlyOwner outOfTime notStopped {
                // send back ether to the bidders
                for(uint i = 1; i < numBidders; i++) { _refund(i); }
                emit Close(highestBidder.addr, highestBidder.amount);
                // send remains to the owner
                destruct();
        }
        event Close(address addr, uint amount);

        function _refund(uint i) private onlyOwner notStopped {
                // check not having been refunded yet
                if(!bidders[i].refunded) {
                        bidders[i].addr.transfer(bidders[i].amount);
                        bidders[i].refunded = true;
                }
                emit Refund(i, bidders[i].addr, bidders[i].amount);
        }
        event Refund(uint num, address addr, uint amount);
}

