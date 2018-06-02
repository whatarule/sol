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


// for exercise

contract Limited {
  modifier limited(uint _num, uint _max) {
    if(_num > _max) {} else _;
  }
  event ReachedMaximum(uint num, uint max);
}

// main
contract Board is Mortal, CircuitBreaker {
  string public name;
  uint public numMessage;
  function Board(string _name) {
    name = _name;
    numMessage = 0;
  }

  struct Message {
    string name = "(blank)";
    string email;
    string content;
  }
}



