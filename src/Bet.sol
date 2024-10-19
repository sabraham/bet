// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

contract Bet {
    uint256 nBets;
    mapping (uint256 => address) yes;
    mapping (uint256 => address) no;
    mapping (uint256 => bool) yesFunded;
    mapping (uint256 => bool) noFunded;
    mapping (uint256 => address) judge;
    mapping (uint256 => uint256) amt;
    mapping (uint256 => BetStatus) status;
    enum BetStatus {
      Created,
      Funded,
      Determined
    }
    function createBet(address _yesAddr, address _noAddr, address _judgeAddr, uint256 _amt) external returns (uint256) {
      uint256 bet = nBets++;
      yes[bet] = _yesAddr;
      no[bet] = _noAddr;
      judge[bet] = _judgeAddr;
      amt[bet] = _amt;
      status[bet] = BetStatus.Created;
      return bet;
    }

    function fund(uint256 _bet) public payable {
      require(msg.value == amt[_bet], "Funding amount did not match bet amount.");
      if (msg.sender == yes[_bet]) {
        if (yesFunded[_bet]) {
          revert("Bet already funded");
        }
        yesFunded[_bet] = true;
      } else if (msg.sender == no[_bet]) {
        if (noFunded[_bet]) {
          revert("Bet already funded");
        }
        noFunded[_bet] = true;
      } else {
        revert("msg.sender must be yes or no address.");
      }
      // could reduce a read call by have it in the if/else block above
      if (yesFunded[_bet] && noFunded[_bet]) {
        status[_bet] = BetStatus.Funded;
      }
    }

    function determine(uint256 _bet, address _winner) public {
      require(msg.sender == judge[_bet], "msg.sender was not judge.");
      require(_winner == yes[_bet] || _winner == no[_bet], "winner was not yes or no.");
      require(status[_bet] == BetStatus.Funded, "status is not Funded.");
      status[_bet] = BetStatus.Determined;
      payable(_winner).transfer(amt[_bet] * 2);
    }
}
