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
    _msg.sender = msg.sender;
  }

  struct User{
    uint id;
    address addr;
    string name;
    string email;
  }
  mapping(uint => User) public users;
  mapping(uint => address) public addresses;
  //mapping(address => User) public toUser;
  //mapping(address => uint) public toID;
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

  struct Msg { address sender; }
  Msg public _msg;
  function test() public {
    //_msg.sender = msg.sender;
    for(uint i = 1; i <= numUsers; i++) {
      require(users[i].addr != msg.sender);
    }
    numUsers++;
    addresses[numUsers] = msg.sender;
    User storage _user = users[numUsers];
      _user.name = "name"; _user.email = "email";
      //_user.addr = _msg.sender;
    emit Registered(numUsers, "name", msg.sender);
  }

  function register(string _name, string _email) external {
    for(uint i = 1; i <= numUsers; i++) {
      require(users[i].addr != msg.sender);
    }
    address _sender = msg.sender;
    numUsers++;
    User storage _user = users[numUsers];
      _user.id = numUsers;
      _user.addr = _sender;
      _user.name = _name; _user.email = _email;
    //User storage _toUser = toUser[_sender]; _toUser;
      //_toUser.id = numUsers;
    emit Registered(numUsers, _name, _sender);
  }
  event Registered(uint num, string name, address addr);

  modifier registered() {
    for(uint i = 1; i <= numUsers; i++) {
      if(users[i].addr == msg.sender) _;
    }
  }
  function submit(string _content) external registered notBlank("content", _content) limited(1000, numMessages) {
    numMessages++;
     Message storage _mssg = messages[numMessages];
       _mssg.content = _content;
       _mssg.addr = msg.sender;
    emit Submit(numMessages, _content, "name");
  }
  event Submit(uint num, string content, string name);

  function reply() external pure {}
}



