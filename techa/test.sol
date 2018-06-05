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
    address addr;
  }
  uint public numStruct;
  mapping (uint => Struct) public structs;
  mapping (uint => address) public toAddr;
  mapping (uint => uint) public toUint;
  Msg public _msg;
  function TestContract() public {
    numStruct = 0;
  }
  function test() public {
    _msg.sender = msg.sender;
    numStruct++;
    //toAddr[numStruct] = _msg.sender;
    Struct storage _st = structs[numStruct];
      _st.addr = msg.sender;
    emit Test(_msg.sender);
  }
  event Test(address sender);
}

