pragma solidity ^0.4.11;

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
  event Stopped(bool _stopped);
  function CircuitBreaker() internal { _stopped = false; }
  modifier not_stopped() {
    if(!_stopped) _;
    else { require(!_paid()); emit Stopped(_stopped); }
  }
  function toggleCircuit(bool _bool) public onlyOwner {
    _stopped = _bool; emit Toggled(_stopped);
  }
  event Toggled(bool _stopped);
  function stopped() external view returns(bool) { return _stopped; }
}

// exercise 11.3
contract Ongoing is Owned, Paid {
  bool private _ongoing;
  mapping(bool => string) internal _status;
  function Ongoing(string _onStatus, string _offStatus) internal {
    _ongoing = true;
    _status[true] = _onStatus;
    _status[false] = _offStatus;
  }

  function status() public { emit Status(_status[_ongoing]); }
  event Status(string _status);
  function changeStatus(bool _bool) internal onlyOwner {
    _ongoing = _bool;
  }

  modifier ongoing() {
    if(_ongoing) _; else { require(!_paid()); status(); }
  }
}
contract MinimumRequired {
  modifier minimumRequired(uint _numMinimum, uint _num) {
    require(_num >= _numMinimum); _;
  }
}

contract Lottery is Ongoing("Accepting...", "Closed"), MinimumRequired, Mortal, CircuitBreaker {

  mapping (uint => address) public applicants;
  uint public numApplicants;
  address public winnerAddress;
  uint public winnerId;

  function Lottery() public {
    numApplicants = 0;
  }

  function enter() external ongoing {
    for(uint i = 1; i < numApplicants+1; i++) {
      require(applicants[i] != msg.sender);
    }
    applicants[numApplicants++] = msg.sender;
  }

  function hold() external minimumRequired(3, numApplicants) {
    winnerId = block.timestamp % numApplicants + 1;
    winnerAddress = applicants[winnerId];
    changeStatus(false);
  }

}
