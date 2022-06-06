pragma solidity >=0.4.22 <0.9.0;

import "./OracleInterface.sol";


/// @title Commitments
/// @author Oliver Song
/// @notice Takes commitments and handles payouts for bill outcomes
contract Commitments {

    // mappings
    mapping(address => bytes32[]) private userToCommitments;
    mapping(bytes32 => Commitment[]) private billToCommitments;

    // bill outcomes oracle
    OracleInterface internal billOracle = new OracleInterface();

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
    /// @param _inSupport commitment in favor of bill passing (vs against)
    /// @return true if the given user has already placed a commitment on the given bill
    function _commitmentIsValid(address _user, bytes32 _billId, bool _inSupport) private view returns (bool) {

        return true;
    }

    /// @notice determines whether or not commitments may still be accepted for the given bill
    /// @param _billId id of a bill
    /// @return true if the bill is commitable
    function _billOpenForCommitment(bytes32 _billId) private view returns (bool) {

        return true;
    }


    /// @notice gets a list ids of all currently commitable bill
    /// @return array of bill ids
    function getCommitableBills() public view returns (bytes32[] memory) {
        return billOracle.getPendingBills();
    }

    /// @notice returns the full data of the specified bill
    /// @param _billId the id of the desired bill
    function getBill(bytes32 _billId) public view returns (
        bytes32 id,
        bytes32 amendsBill,
        string memory sponsor,
        uint dateOfIntroduction,
        string memory committees,
        string memory latestAction,
        uint latestActionDate,
        string memory title,
        string memory legislationNumber,
        OracleInterface.BillOutcome outcome) {

        return billOracle.getBill(_billId);
    }

    /// @notice returns the full data of the most recent commitable bill
    function getMostRecentBill() public view returns (
        bytes32 id,
        bytes32 amendsBill,
        string memory sponsor,
        uint dateOfIntroduction,
        string memory committees,
        string memory latestAction,
        uint latestActionDate,
        string memory title,
        string memory legislationNumber,
        OracleInterface.BillOutcome outcome) {

        return billOracle.getMostRecentBill(true);
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
        require(_billOpenForCommitment(_billId), "Bill not open for commitment");

        // transfer the money into the account
        // address(this).transfer(msg.value);

        // add the new commitment
        Commitment[] storage commitments = billToCommitments[_billId];
        commitments.push(Commitment(msg.sender, _billId, msg.value, _inSupport));

        // add the mapping
        bytes32[] storage userCommitments = userToCommitments[msg.sender];
        userCommitments.push(_billId);
    }

    /// @notice for testing only; adds two numbers and returns result
    /// @return uint sum of two uints
    function test(uint a, uint b) public pure returns (uint) {
        return (a + b);
    }
}
