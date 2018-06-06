pragma solidity ^0.4.11;

contract Owned {
  address private _owner;
  function Owned() internal { _owner = msg.sender; }
  modifier onlyOwner { require(msg.sender == _owner); _; }
  function owner() external view returns(address) { return _owner; }
}
contract Mortal is Owned {
  event Destructed();
  function destruct() public onlyOwner { emit Destructed(); selfdestruct(msg.sender); }
}

contract TestContract is Mortal {
  struct Msg { address sender; }
  struct Struct {
    string name;
  }
  uint public numStruct;
  mapping (uint => string) public toStr;
  mapping (uint => address) public toAddr;
  mapping (address => Struct) public structs;
  Msg public _msg;
  function TestContract() public {
    numStruct = 0;
  }
  function test() public {
    _msg.sender = msg.sender;
    numStruct++;
    //toStr[1] = "aaa";
    //toAddr[1] = _msg.sender;
    structs[msg.sender] = Struct({name: "name"});
    emit Test(_msg.sender);
  }
  event Test(address sender);
}

