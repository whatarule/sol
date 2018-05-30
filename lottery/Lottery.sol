
pragma solidity ^0.4.11;

contract Owned {
  address public owner;
  function Owned() public {
    owner = msg.sender;
  }
  modifier onlyOwner {
    require(msg.sender == owner); _;
  }
}

contract Mortal is Owned{
  function kill() public onlyOwner {
    selfdestruct(owner);
  }
}
contract CircuitBreaker is Owned {
  bool public stopped;
  function CircuitBreaker() public {
    stopped = false;
  }
  modifier isStopped() {
    require(!stopped); _;
  }
  function toggleCircuit(bool _stopped) public onlyOwner {
    stopped = _stopped;
  }
}

contract MinimumRequired {
  modifier minimumRequired(uint _numMinimum, uint _num) {
    require(_num >= _numMinimum); _;
  }
}

contract Lottery is MinimumRequired, Mortal, CircuitBreaker{

  mapping (uint => address) public applicants;
  uint public numApplicants;
  address public winnerAddress;
  uint public winnerId;
  bool public onGoing;

  function Lottery public {
    numApplicants = 0;
    onGoing = true;
  }

  function enter() public {
    require(onGoing);
    for(uint i = 1; i < numApplicants+1; i++) {
      require(applicants[i] != msg.sender);
    }
    applicants[numApplicants++] = msg.sender;
  }

  function hold() public minimumRequired(3, numApplicants) {
    winnerId = block.timestamp % numApplicants + 1;
    winneorAddress = applicants[winnerId];
    onGoing = false;
  }

}
