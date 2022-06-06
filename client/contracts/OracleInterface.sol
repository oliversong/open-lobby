pragma solidity >=0.4.22 <0.9.0;

contract OracleInterface {
    mapping(bytes32 => uint) billIdToIndex;
    Bill[] bills;

    // defines a bill along with its outcome
    struct Bill {
        bytes32 id;
        bytes32 amendsBill;
        string sponsor;
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

    /// @notice gets the specified bill
    /// @param _billId the unique id of the desired bill
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
        BillOutcome outcome) {

        //get the bill
        if (billExists(_billId)) {
            Bill storage theBill = bills[_getBillIndex(_billId)];
            return (theBill.id, theBill.amendsBill, theBill.sponsor, theBill.dateOfIntroduction, theBill.committees, theBill.latestAction, theBill.latestActionDate, theBill.title, theBill.legislationNumber, theBill.outcome);
        }
        else {
            return (_billId, 0, "", 0, "", "", 0, "", "", BillOutcome.Pending);
        }
    }

    /// @notice gets the most recent bill or pending bill
    /// @param _pending if true, will return only the most recent pending bill; otherwise, returns the most recent bill either pending or completed
    function getMostRecentBill(bool _pending) public view returns (
        bytes32 id,
        bytes32 amendsBill,
        string memory sponsor,
        uint dateOfIntroduction,
        string memory committees,
        string memory latestAction,
        uint latestActionDate,
        string memory title,
        string memory legislationNumber,
        BillOutcome outcome) {

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
}
