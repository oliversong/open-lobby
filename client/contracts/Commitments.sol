// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./OracleInterface.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/// @title Commitments
/// @author Oliver Song
/// @notice Takes commitments and handles payouts for bill outcomes
contract Commitments is Ownable {
    // mappings
    mapping(address => bytes32[]) private userToCommitments;
    mapping(bytes32 => Commitment[]) private billToCommitments;
    mapping(bytes32 => bool) internal billPaidOut;

    // bill outcomes oracle
    address internal billOracleAddr = address(0);
    OracleInterface internal billOracle = OracleInterface(billOracleAddr);

    //constants
    uint internal minimumCommitment = 1000000000000;  // 1000 gwei
    uint internal housePercentage = 2;

    event Transferral(address, address, uint);

    using SafeMath for uint;

    struct Commitment {
        address user;
        bytes32 billId;
        uint amount;
        bool inSupport;
    }

    /// @notice determines whether or not the user has already committed to the given bill
    /// @param _user address of a user
    /// @param _billId id of a bill
    /// @return true if the given user has already placed a commitment on the given bill
    function _commitmentIsValid(address _user, bytes32 _billId) private view returns (bool) {
        bytes32[] memory userCommitments = userToCommitments[_user];
        if (userCommitments.length > 0) {
            for (uint n = 0; n < userCommitments.length; n++) {
                if (userCommitments[n] == _billId) {
                    return false;
                }
            }
        }
        return true;
    }

    /// @notice gets a list ids of all currently commitable bill
    /// @return array of bill ids
    function getCommitableBills() public view returns (bytes32[] memory) {
        return billOracle.getPendingBills();
    }

    /// @notice returns the full data of the specified bill
    /// @param _billId the id of the desired bill
    function getBill(bytes32 _billId) public view returns (OracleInterface.Bill memory) {
        return billOracle.getBill(_billId);
    }

    /// @notice returns the full data of the most recent commitable bill
    function getMostRecentBill() public view returns (OracleInterface.Bill memory) {
        return billOracle.getMostRecentBill(true);
    }

    /// @notice gets the current bills on which the user has commitments
    /// @return array of bill ids
    function getUserCommitments() public view returns (bytes32[] memory) {
        return userToCommitments[msg.sender];
    }

    /// @notice gets the current commitments for the bill
    /// @param _billId the id of the desired bill
    /// @return array of Commitments
    function getBillCommitments(bytes32 _billId) public view returns (Commitment[] memory) {
        return billToCommitments[_billId];
    }

    /// @notice gets a user's commitment
    /// @param _billId the id of the desired bill
    /// @return amount commitment amount, or 0 if no commitment found
    /// @return inSupport in support of bill or not, or 0 if no commitment found
    function getUserCommitment(bytes32 _billId) public view returns (uint amount, bool inSupport) {
        // FIXME: perhaps should iterate through usercommitments instead
        // actually, probably shouldn't be iterating at all if possible
        Commitment[] storage commitments = billToCommitments[_billId];
        for (uint n = 0; n < commitments.length; n++) {
            if (commitments[n].user == msg.sender) {
                return (commitments[n].amount, commitments[n].inSupport);
            }
        }
        // FIXME could gate this with a require and instead
        // add a method "userHasCommitment".
        // Could also gate billid on existing bill
        return (0, false);
    }

    /// @notice places a non-rescindable commitment on the given bill
    /// @param _amount the id of the bill on which to commitment
    /// @param _billId the id of the bill on which to commitment
    /// @param _inSupport commitment in favor of bill passing (vs against)
    function placeCommitment(uint _amount, bytes32 _billId, bool _inSupport) public payable {
        require(msg.value == _amount);

        // commitment must be above a certain minimum
        require(_amount >= minimumCommitment, "Commitment amount must be >= minimum commitment");

        // make sure that bill exists
        require(billOracle.billExists(_billId), "Specified bill not found");

        // validate
        require(_commitmentIsValid(msg.sender, _billId), "Commitment is not valid");

        // bill must still be open for commitment
        require(billOracle.billIsPending(_billId), "Bill not open for commitment");

        // add the new commitment
        Commitment[] storage commitments = billToCommitments[_billId];
        commitments.push(Commitment(msg.sender, _billId, _amount, _inSupport));

        // add the mapping
        bytes32[] storage userCommitments = userToCommitments[msg.sender];
        userCommitments.push(_billId);
    }

    function _payOutWinnings(address _user, uint _amount) private {
        emit Transferral(address(this), _user, _amount);
        payable(_user).transfer(_amount);
    }

    function _transferToHouse() private {
        emit Transferral(address(this), owner, address(this).balance);
        payable(owner).transfer(address(this).balance);
    }

    function _isWinningCommitment(OracleInterface.BillOutcome _outcome, bool inSupport) private pure returns (bool) {
        require(_outcome != OracleInterface.BillOutcome.Pending);

        if (_outcome == OracleInterface.BillOutcome.BecameLaw) {
            if (inSupport) {
                return true;
            } else {
                return false;
            }
        } else {
            if (inSupport) {
                return false;
            } else {
                return true;
            }
        }
    }

    /// @notice calculates the amount to be paid out for a commitment
    /// @param _winningTotal the total monetary amount of winning commitments
    /// @param _losingTotal the total monetary amount of losing commitments
    /// @param _committedAmount the amount of this particular commitment
    /// @return an amount in wei
    function _calculatePayout(uint _winningTotal, uint _losingTotal, uint _committedAmount, bool _keepCommitment) private view returns (uint) {
        uint percentWinningTotal = _committedAmount.div(_winningTotal);

        // calculate raw share
        uint winningAmount = 0;
        if (_keepCommitment) {
            winningAmount = _losingTotal.mul(percentWinningTotal) + _committedAmount;
        } else {
            winningAmount = _losingTotal.mul(percentWinningTotal);
        }

        // if share has been rounded down to zero, fix that
        if (winningAmount == 0) {
            winningAmount = minimumCommitment;
        }

        // take out house cut
        return winningAmount - winningAmount.mul(housePercentage).div(100);
    }

    /// @notice calculates how much to pay out to each winner, then pays each winner the appropriate amount
    /// @param _billId the unique id of the bill
    /// @param _outcome the bill's outcome
    function _payOutForBill(bytes32 _billId, OracleInterface.BillOutcome _outcome) private {
        require(_outcome != OracleInterface.BillOutcome.Pending);

        Commitment[] storage commitments = billToCommitments[_billId];
        uint losingTotal = 0;
        uint winningTotal = 0;
        uint[] memory payouts = new uint[](commitments.length);

        //count winning commitments & get total
        for (uint n = 0; n < commitments.length; n++) {
            uint amount = commitments[n].amount;
            if (_isWinningCommitment(_outcome, commitments[n].inSupport)) {
                winningTotal = winningTotal.add(amount);
            } else {
                losingTotal = losingTotal.add(amount);
            }
        }

        //calculate payouts
        for (uint n = 0; n < commitments.length; n++) {
            if (_outcome == OracleInterface.BillOutcome.BecameLaw) {
                // in the passing case, supporters get detractors' commitments
                // minus their own commitment, which goes to legislator
                if (_isWinningCommitment(_outcome, commitments[n].inSupport)) {
                    payouts[n] = _calculatePayout(winningTotal, losingTotal, commitments[n].amount, false);
                } else {
                    payouts[n] = 0;
                }
            } else {
                // in the rejected case, detractors get supporters' commitments
                // plus their own back. Legislators get nothing.
                if (_isWinningCommitment(_outcome, commitments[n].inSupport)) {
                    payouts[n] = _calculatePayout(winningTotal, losingTotal, commitments[n].amount, true);
                } else {
                    payouts[n] = 0;
                }
            }
        }

        // calculate legislator payout
        uint legislatorPayout = 0;
        if (_outcome == OracleInterface.BillOutcome.BecameLaw) {
            // legislator gets support total
            legislatorPayout = winningTotal;
        }


        // pay out to users
        for (uint n = 0; n < payouts.length; n++) {
            if (payouts[n] != 0) {
                _payOutWinnings(commitments[n].user, payouts[n]);
            }
        }

        // pay out to legislators
        if (legislatorPayout != 0) {
            address sponsor = billOracle.getBillSponsorAddress(_billId);
            _payOutWinnings(sponsor, legislatorPayout);
        }

        // transfer the remainder to the house
        _transferToHouse();

        // mark bill as paid out
        billPaidOut[_billId] = true;
    }


    /// @notice check the outcome of the given bill; if ready, will trigger calculation of payout, and actual payout to winners
    /// @param _billId the id of the bill to check
    /// @return the outcome of the given bill
    function checkOutcome(bytes32 _billId) external onlyOwner returns (OracleInterface.BillOutcome)  {
        OracleInterface.Bill memory b = getBill(_billId);

        if (b.outcome != OracleInterface.BillOutcome.Pending && !billPaidOut[_billId]) {
            _payOutForBill(_billId, b.outcome);
        }

        return b.outcome;
    }


    /// @notice sets the address of the oracle contract to use
    /// @dev setting a wrong address may result in false return value, or error
    /// @param _oracleAddress the address of the oracle
    /// @return true if connection to the new oracle address was successful
    function setOracleAddress(address _oracleAddress) external onlyOwner returns (bool) {
        billOracleAddr = _oracleAddress;
        billOracle = OracleInterface(billOracleAddr);
        return billOracle.testConnection();
    }

    /// @notice gets the address of the oracle being used
    /// @return the address of the currently set oracle
    function getOracleAddress() external view returns (address) {
        return billOracleAddr;
    }

    /// @notice for testing; tests that the oracle is callable
    /// @return true if connection successful
    function testOracleConnection() public view returns (bool) {
        return billOracle.testConnection();
    }
}
