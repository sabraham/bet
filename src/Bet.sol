// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;
import {console} from "forge-std/console.sol";

/**
 * A demo smart contract that allows two parties to place a 1:1 wager and a
 * third-party to adjudicate the winner.
 */
contract Bet {
    uint256 nBets;

    struct BetData {
        address yes;
        address no;
        address judge;
        bool yesFunded;
        bool noFunded;
        uint256 amt;
        BetStatus status;
    }

    mapping(uint256 => BetData) bets;

    enum BetStatus {
        Created,
        Funded,
        Determined
    }

    function createBet(address _yesAddr, address _noAddr, address _judgeAddr, uint256 _amt)
        external
        returns (uint256)
    {
        uint256 bet = nBets++;

        BetData storage betData = bets[bet];

        betData.yes = _yesAddr;
        betData.no = _noAddr;
        betData.judge = _judgeAddr;
        betData.amt = _amt;
        betData.status = BetStatus.Created;
        return bet;
    }

    function fund(uint256 _bet) public payable {
        BetData storage bet = bets[_bet];
        require(msg.value == bet.amt, "Funding amount did not match bet amount.");
        if (msg.sender == bet.yes) {
            if (bet.yesFunded) {
                revert("Bet already funded");
            }
            bet.yesFunded = true;
        } else if (msg.sender == bet.no) {
            if (bet.noFunded) {
                revert("Bet already funded");
            }
            bet.noFunded = true;
        } else {
            revert("msg.sender must be yes or no address.");
        }
        // could reduce a read call by have it in the if/else block above
        if (bet.yesFunded && bet.noFunded) {
            bet.status = BetStatus.Funded;
        }
    }

    function determine(uint256 _bet, address _winner) public {
        BetData storage bet = bets[_bet];
        require(msg.sender == bet.judge, "msg.sender was not judge.");
        require(_winner == bet.yes || _winner == bet.no, "winner was not yes or no.");
        require(bet.status == BetStatus.Funded, "status is not Funded.");
        bet.status = BetStatus.Determined;
        payable(_winner).transfer(bet.amt * 2);
    }
}
