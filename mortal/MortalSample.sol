pragma solidity ^0.4.11;

contract Mortal {
  address public owner;
  function Mortal() public {
    owner = msg.sender;
  }
  function kill() public {
    selfdestruct(owner);
  }
}
