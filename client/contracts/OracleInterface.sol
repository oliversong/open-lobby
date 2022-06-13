// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract OracleInterface {
    enum BillOutcome {
        Pending,
        BecameLaw,
        TimedOut
    }

    function getPendingBills() public view returns (bytes32[] memory);

    function getAllBills() public view returns (bytes32[] memory);

    function billExists(bytes32 _billId) public view returns (bool);

    function getBill(bytes32 _billId) public view returns (
        bytes32 id,
        string memory sponsor,
        uint dateOfIntroduction,
        string memory title,
        string memory legislationNumber,
        BillOutcome outcome);

    function getAdditionalBillInfo(bytes32 _billId) public view returns (
        string memory amendsBill,
        string memory committees,
        string memory latestAction,
        uint latestActionDate);

    function getMostRecentBill(bool _pending) public view returns (
        bytes32 id,
        string memory sponsor,
        uint dateOfIntroduction,
        string memory title,
        string memory legislationNumber,
        BillOutcome outcome);

    function testConnection() public pure returns (bool);

    function addTestData() public;
}
