// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./OracleInterface.sol";
import "./Ownable.sol";

/// @title Commitments
/// @author Oliver Song
/// @notice Takes commitments and handles payouts for bill outcomes
contract Commitments is Ownable {
    // mappings
    mapping(address => bytes32[]) private userToCommitments;
    mapping(bytes32 => Commitment[]) private billToCommitments;

    // bill outcomes oracle
    address internal billOracleAddr = address(0);
    OracleInterface internal billOracle = OracleInterface(billOracleAddr);

    //constants
    uint internal minimumCommitment = 1000000000000;

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
        bytes32[] storage userCommitments = userToCommitments[msg.sender];
        if (userCommitments.length > 0) {
            for (uint n = 0; n < userCommitments.length; n++) {
                if (userBets[n] == _billId) {
                    return false
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
    function getUserCommitments() public view returns (bytes32[]) {
        return userToCommitments[msg.sender];
    }

    /// @notice gets a user's commitment
    /// @param _billId the id of the desired bill
    /// @return tuple containing the commitment amount, and the pass result (or (0,0) if no bet found)
    function getUserCommitment(bytes32 _billId) public view returns (uint amount, bool inSupport) {
        Commitment[] storage commitments = billToCommitments[_billId];
        for (uint n = 0; n < commitments.length; n++) {
            if (commitments[n].user == msg.sender) {
                return (commitments[n].amount, bets[n].inSupport);
            }
        }
        return (0, false);
    }

    /// @notice places a non-rescindable commitment on the given bill
    /// @param _billId the id of the bill on which to commitment
    /// @param _inSupport commitment in favor of bill passing (vs against)
    function placeCommitment(bytes32 _billId, bool _inSupport) public payable {

        // commitment must be above a certain minimum
        require(msg.value >= minimumCommitment, "Commitment amount must be >= minimum commitment");

        // make sure that bill exists
        require(billOracle.billExists(_billId), "Specified bill not found");

        // validate
        require(_commitmentIsValid(msg.sender, _billId, _inSupport), "Commitment is not valid");

        // bill must still be open for commitment
        require(billOracle.billIsPending(_billId), "Bill not open for commitment");

        // transfer the money into the account
        address(this).transfer(msg.value);

        // add the new commitment
        Commitment[] storage commitments = billToCommitments[_billId];
        commitments.push(Commitment(msg.sender, _billId, msg.value, _inSupport));

        // add the mapping
        bytes32[] storage userCommitments = userToCommitments[msg.sender];
        userCommitments.push(_billId);
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
