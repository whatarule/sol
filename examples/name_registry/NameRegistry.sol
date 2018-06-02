
pragma solidity ^0.4.11;

contract NameRegistry {
  struct Contract {
    address owner;
    address addr;
    bytes32 description;
  }

  uint public numContracts;
  mapping (bytes32 => Contract) public contracts;
  function NameRegistry() public {
    numContracts = 0;
  }

  function register(bytes32 _name) public returns (bool) {
    if(contracts[_name].owner = 0) {
      Contract con = contracts[_name]
    }
  }
}

