const Commitments = artifacts.require("Commitments");

contract("Commitments", (accounts) => {
  it("should send money", async () => {
    const instance = await Commitments.deployed();
    const amt = 100

    const owner = accounts[0];
    const contractAddress = instance.address;
    const testAcc = accounts[1];

    await instance.sendTransaction({from:owner,value: amt})

    const ownerStartingBalance = await web3.eth.getBalance(owner)
    const contractStartingBalance = await web3.eth.getBalance(contractAddress)
    const testAccStartingBalance = await web3.eth.getBalance(testAcc)

    await instance._payOutWinnings(testAcc, amt);

    // Get balances of first and second account after the transactions.
    const contractEndingBalance = await web3.eth.getBalance(contractAddress)
    const testAccEndingBalance = await web3.eth.getBalance(testAcc)

    assert.equal(
      contractEndingBalance,
      contractStartingBalance - amt,
      "Amount wasn't correctly taken from the contract"
    );
    assert.equal(
      testAccEndingBalance,
      testAccStartingBalance + amt,
      "Amount wasn't correctly sent to the receiver"
    );
  });
});
