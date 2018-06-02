pragma solidity ^0.4.11;

// Utility Contracts
contract Owned {
        address private _owner;
        function Owned() internal { _owner = msg.sender; }
        modifier onlyOwner { require(msg.sender == _owner); _; }
        function owner() external view returns(address) { return _owner; }
}

contract Paid {
        function _paid() internal view returns(bool) {
                return msg.value > 0;
        }
}

contract Mortal is Owned {
        event Destructed();
        function destruct() public onlyOwner { emit Destructed(); selfdestruct(msg.sender); }
}
contract CircuitBreaker is Owned, Paid {
        bool private _stopped;
        function CircuitBreaker() internal { _stopped = false; }
        modifier notStopped() {
                if(!_stopped) _;
                else { require(!_paid()); emit Stopped(_stopped); }
        }
        event Stopped(bool _stopped);
        function toggleCircuit(bool _bool) public onlyOwner {
                _stopped = _bool; emit Toggled(_stopped);
        }
        event Toggled(bool _stopped);
        function stopped() external view returns(bool) { return _stopped; }
}


// exercise 11.3

// for Lottery status
contract Ongoing is Owned, Paid {
        bool private _ongoing;
        mapping(bool => string) internal _status;
        function Ongoing(string _onStatus, string _offStatus) internal {
                _ongoing = true;
                _status[true] = _onStatus;
                _status[false] = _offStatus;
        }

        function status() public view returns(string) {
                return _status[_ongoing];
        }
        event Status(string _status);

        function toggleOngoing(bool _bool) internal onlyOwner {
                _ongoing = _bool; emit Status(status());
        }
        modifier ongoing() {
                if(_ongoing) _; else { require(!_paid()); emit Status(status()); }
        }
}
contract MinimumRequired {
        modifier minimumRequired(uint _numMinimum, uint _num) {
                if(_num < _numMinimum) emit Required(_num, _numMinimum); else _;
        }
        event Required(uint num, uint min);
}

// Main Contract
contract Lottery is Ongoing, MinimumRequired, Mortal, CircuitBreaker {

        mapping (uint => address) public applicants;
        uint public numApplicants;
        address public winnerAddress;
        uint public winnerId;

        function Lottery() public Ongoing("Accepting...", "Closed") {
                numApplicants = 0;
        }

        function enter() external ongoing {
                for(uint i = 1; i <= numApplicants; i++) {
                        require(applicants[i] != msg.sender);
                }
                numApplicants++;
                applicants[numApplicants] = msg.sender;
                emit Enter(numApplicants, msg.sender);
        }
        event Enter(uint num, address addr);

        function hold() external minimumRequired(3, numApplicants) ongoing {
                toggleOngoing(false);
                winnerId = block.timestamp % numApplicants + 1;
                winnerAddress = applicants[winnerId];
                emit Winner(winnerId, winnerAddress);
        }
        event Winner(uint id, address addr);

}
