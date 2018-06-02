pragma solidity ^0.4.11;
contract HelloEthereum {
  string public msg1;
  string private msg2;
  address public owner;
  uint8 public counter;

  // Constructors
  // - Defined as functions and have the same name to the contracs.
  function HelloEthereum(string _msg1) public {
    msg1 = _msg1;
    owner = msg.sender;
    counter = 0;
  }

  // Setter
  function setMsg2(string _msg2) public {
    if(owner == msg.sender) {
      msg2 = _msg2;
    } else {
      revert();
    }
  }
  // Getter
  function getMsg2() constant public returns(string) {
    return msg2;
  }

  function setCounter() public {
    for(uint i = 0; i < 3; i++) {
      counter++;
    }
  }
}

