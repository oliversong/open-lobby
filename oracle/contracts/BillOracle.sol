pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./DateLib.sol";

/*
TEST:
- testConnection
- getAddress
- billExists(0)
- billExists(1)
- declareOutcome(0, 2)
- getPendingBills()
- getAllBills()
- getBill(0)
- getMostRecentBill(true)
- addTestData()
- billExists(0)
- billExists(1)
- declareOutcome(0, 2)
- getPendingBills()
- getAllBills()
- getBill(0)
- getMostRecentBill(true)
- getMostRecentBill(false)
- getBill(0x...)
- declareOutcome(0x..., 2)
- getMostRecentBill(true)
- getMostRecentBill(false)
- getBill(0x...)
- add duplicate bill
*/

/// @title BillOracle
/// @author Oliver
/// @notice Collects and provides information on bills and their status
contract BillOracle is Ownable {
    mapping(bytes32 => uint) billIdToIndex;
    Bill[] bills;

    using DateLib for DateLib.DateTime;

    // defines a bill along with its outcome
    struct Bill {
        bytes32 id;
        string amendsBill;
        string sponsor;
        address sponsorAddress;
        uint dateOfIntroduction;
        string committees;
        string latestAction;
        uint latestActionDate;
        string title;
        string legislationNumber;
        BillOutcome outcome;
    }

    enum BillOutcome {
        Pending,
        BecameLaw,
        TimedOut
    }

    /// @notice returns the array index of the bill with the given id
    /// @dev if the bill id is invalid, then the return value will be incorrect and may cause error; you must call billExists(_billId) first!
    /// @param _billId the bill id to get
    /// @return an array index
    function _getBillIndex(bytes32 _billId) private view returns (uint) {
        return billIdToIndex[_billId]-1;
    }


    /// @notice determines whether a bill exists with the given id
    /// @param _billId the bill id to test
    /// @return true if bill exists and id is valid
    function billExists(bytes32 _billId) public view returns (bool) {
        if (bills.length == 0)
            return false;
        uint index = billIdToIndex[_billId];
        if (index > 0) {
            return true;
        } else {
            return false;
        }
    }

    function billIsPending(bytes32 _billId) public view returns (bool) {
        require(billExists(_billId));
        uint index = _getBillIndex(_billId);
        Bill memory b = bills[index];
        if (b.outcome == BillOutcome.Pending) {
          return true;
        }

        return false;
    }

    /// @notice puts a new bill into the blockchain
    /// @return the unique id of the newly created bill
    function addBill(
        string memory _amendsBill,
        string memory _sponsor,
        address _sponsorAddress,
        uint _dateOfIntroduction,
        string memory _committees,
        string memory _latestAction,
        uint _latestActionDate,
        string memory _title,
        string memory _legislationNumber) onlyOwner public returns (bytes32) {

        // hash the crucial info to get a unique id
        bytes32 id = keccak256(abi.encodePacked(_sponsor, _dateOfIntroduction, _title, _legislationNumber));

        // require that the bill be unique (not already added)
        require(!billExists(id));

        // add the bill
        uint newIndex = bills.push(Bill(id, _amendsBill, _sponsor, _sponsorAddress, _dateOfIntroduction, _committees, _latestAction, _latestActionDate, _title, _legislationNumber, BillOutcome.Pending)) - 1;
        billIdToIndex[id] = newIndex + 1;

        // return the unique id of the new bill
        return id;
    }

    /// @notice sets the outcome of a predefined bill, permanently on the blockchain
    /// @param _billId unique id of the bill to modify
    /// @param _outcome outcome of the bill
    function declareOutcome(bytes32 _billId, BillOutcome _outcome) onlyOwner external {

        // require that it exists
        require(billExists(_billId));

        // get the bill
        uint index = _getBillIndex(_billId);
        Bill storage theBill = bills[index];

        // set the outcome
        theBill.outcome = _outcome;

        // TODO: trigger checkOutcome on commitments side? how?
    }

    /// @notice gets the unique ids of all pending bills, in reverse chronological order
    /// @return an array of unique bill ids
    function getPendingBills() public view returns (bytes32[] memory) {
        uint count = 0;

        // get count of pending bills
        for (uint i = 0; i < bills.length; i++) {
            if (bills[i].outcome == BillOutcome.Pending)
                count++;
        }

        //collect up all the pending bills
        bytes32[] memory output = new bytes32[](count);

        if (count > 0) {
            uint index = 0;
            for (uint n = bills.length; n > 0; n--) {
                if (bills[n-1].outcome == BillOutcome.Pending)
                    output[index++] = bills[n-1].id;
            }
        }

        return output;
    }

    /// @notice gets the unique ids of bills, pending and decided, in reverse chronological order
    /// @return an array of unique bill ids
    function getAllBills() public view returns (bytes32[] memory) {
        bytes32[] memory output = new bytes32[](bills.length);

        //get all ids
        if (bills.length > 0) {
            uint index = 0;
            for (uint n = bills.length; n > 0; n--) {
                output[index] = bills[n-1].id;
                index++;
            }
        }

        return output;
    }

    /// @notice gets the specified bill
    /// @param _billId the unique id of the desired bill
    function getBill(bytes32 _billId) public view returns (Bill memory) {
        require(billExists(_billId), "Bill does not exist");
        return bills[_getBillIndex(_billId)];
    }

    /// @notice gets the most recent bill or pending bill
    /// @param _pending if true, will return only the most recent pending bill; otherwise, returns the most recent bill either pending or completed
    function getMostRecentBill(bool _pending) public view returns (Bill memory) {

        bytes32 billId = 0;
        bytes32[] memory ids;

        if (_pending) {
            ids = getPendingBills();
        } else {
            ids = getAllBills();
        }
        if (ids.length > 0) {
            billId = ids[0];
        }

        //by default, return a null bill
        return getBill(billId);
    }

    function getBillSponsorAddress(bytes32 _billId) public view returns (address) {
        require(billExists(_billId), "Bill does not exist");
        return bills[_getBillIndex(_billId)].sponsorAddress;
    }

    /// @notice can be used by a client contract to ensure that they've connected to this contract interface successfully
    /// @return true, unconditionally
    function testConnection() public pure returns (bool) {
        return true;
    }

    /// @notice gets the address of this contract
    /// @return address
    function getAddress() public view returns (address) {
        return address(this);
    }

    function makeTestAddress() private view onlyOwner returns (address) {
        return address(uint256(keccak256(abi.encodePacked(now))));
    }

    /// @notice for testing
    function addTestData() external onlyOwner {
        addBill("", "George Clooney", makeTestAddress(), DateLib.DateTime(2022, 1, 20, 0, 0, 0, 0, 0).toUnixTimestamp(), "", "", 0, "Proposal to do the thing", "m23t4930gj");
        addBill("", "Bill Nye", makeTestAddress(), DateLib.DateTime(2022, 5, 20, 0, 0, 0, 0, 0).toUnixTimestamp(), "", "", 0, "Proposal to do the other thing", "r30t294gr");
        addBill("", "Adam Driver", makeTestAddress(), DateLib.DateTime(2022, 1, 19, 0, 0, 0, 0, 0).toUnixTimestamp(), "", "", 0, "Proposal to do the other other thing", "i230t94jgre");
        addBill("0m23t4930gj", "Sean Livingston", makeTestAddress(), DateLib.DateTime(2022, 5, 10, 0, 0, 0, 0, 0).toUnixTimestamp(), "", "", 0, "Proposal to roll back the thing", "m23t4930gj");
        addBill("", "Sanjit Biswas", makeTestAddress(), DateLib.DateTime(2021, 1, 20, 0, 0, 0, 0, 0).toUnixTimestamp(), "", "", 0, "Proposal to make money", "42tg90jg");
        addBill("", "John Bicket", makeTestAddress(), DateLib.DateTime(2021, 2, 20, 0, 0, 0, 0, 0).toUnixTimestamp(), "", "", 0, "Proposal to build it", "gjeotw5990");
    }
}
