// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

abstract contract OracleInterface {
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

    function getPendingBills() public virtual view returns (bytes32[] memory);

    function getAllBills() public virtual view returns (bytes32[] memory);

    function billExists(bytes32 _billId) public virtual view returns (bool);

    function getBill(bytes32 _billId) public virtual view returns (Bill memory);

    function getMostRecentBill(bool _pending) public virtual view returns (Bill memory);

    function testConnection() public virtual pure returns (bool);

    function addTestData() public virtual;
}
