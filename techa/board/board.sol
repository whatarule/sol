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

contract Limited is Paid {
  modifier limited(uint _max, uint _num) {
    if(_num > _max) { require(!_paid()); emit ReachedMaximum(_max, _num); } else _;
  }
  event ReachedMaximum(uint max, uint num);
}

// main
contract Board is Mortal, CircuitBreaker, Limited {
  string public nameBoard;
  uint public numUsers;
  uint public numMessages;
  function Board() public {
  //function Board(string _name) public {
  //  nameBoard = _name;
    nameBoard = "test";
    numMessages = 0;
    numUsers = 0;
  }

  struct User{
    uint num;
    string name;
    //string email;
  }
  mapping(address => User) public users;
  struct Message {
    string content;
    address addr;
  }
  mapping(uint => Message) public messages;

  modifier notBlank(string _name, string _str) {
    if(bytes(_str).length == 0) { require(!_paid()); emit Blank(_name); } else _;
  }
  event Blank(string name);
  modifier defaultValue(string _var, string _default) {
    if(bytes(_var).length == 0) { _var = _default; } _;
  }

  function test() external {
    string memory _name = "name";
    numUsers++;
    users[msg.sender] = User({num: numUsers, name: _name});
    emit Registered(numUsers, _name, msg.sender);
  }

  modifier unregistered() {
    User storage _u = users[msg.sender];
    if(_u.num == 0) { require(!_paid()); emit Registered(_u.num, _u.name, msg.sender); } else _;
  }
  function register(string _name) external unregistered {
    numUsers++;
    users[msg.sender] = User({num: numUsers, name: _name});
    emit Registered(numUsers, _name, msg.sender);
  }
  event Registered(uint num, string name, address addr);

  modifier registered() {
    User storage _u = users[msg.sender];
    if(bytes(_u.name).length != 0) { require(!_paid()); emit Unregistered(msg.sender); } else _;
  }
  function submit(string _content) external registered notBlank("content", _content) limited(1000, numMessages) {
    numMessages++;
     Message storage _mssg = messages[numMessages];
       _mssg.content = _content;
       _mssg.addr = msg.sender;
    emit Submit(numMessages, _content, "name");
  }
  event Unregistered(address addr);
  event Submit(uint num, string content, string name);

  function reply() external pure {}
}



