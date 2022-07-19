# open-lobby

Currently running on the Rinkeby Testnet:
* [Oracle Contract](https://rinkeby.etherscan.io/address/0x591A9b66722340a760b9287DDBa22BBFEE028CFb)
* [Commitment Manager Contract](https://rinkeby.etherscan.io/address/0xC86d52268D772cEC8bb3DC157E18Bd132b99b35E)

### start the webserver
```
cd web-service
npm start
```

### start the truffle webserver, open a console to the oracle
```
cd oracle
truffle develop
```

### open a console to the commitment manager
```
cd client
truffle develop
```

### interacting with the contract
```
// oracle console
truffle(develop)> migrate
truffle(develop)> BillOracle.deployed().then(inst => { instance = inst })
truffle(develop)> instance.testConnection()
truffle(develop)> instance.addTestData()
truffle(develop)> instance.getAllBills()
truffle(develop)> instance.getAddress()

// client console
truffle(develop)> migrate
truffle(develop)> Commitments.deployed().then(inst => { instance = inst })
truffle(develop)> instance.setOracleAddress('0x49463b9E60AF0F70489207f6566b8A10377F4f57')
truffle(develop)> instance.testOracleConnection()

truffle(develop)> let accounts = await web3.eth.getAccounts()
truffle(develop)> acc0 = accounts[0];acc1 = accounts[1];acc2 = accounts[2];acc3 = accounts[3];acc4 = accounts[4]
truffle(develop)> instance.placeCommitment('250000000000000000', '0x0121452db83fd9c77975fd5647f8cc6a8223c5431d6c7111632c6cb7013b7efd', true, {value:'250000000000000000', from: acc1})
truffle(develop)> instance.getUserCommitments()
truffle(develop)> instance.placeCommitment('250000000000000000', '0x0121452db83fd9c77975fd5647f8cc6a8223c5431d6c7111632c6cb7013b7efd', false, {value:'250000000000000000', from: acc2})
truffle(develop)> instance.getBillCommitments('0x0121452db83fd9c77975fd5647f8cc6a8223c5431d6c7111632c6cb7013b7efd')

// declare outcome on oracle
instance.declareOutcome('0x0121452db83fd9c77975fd5647f8cc6a8223c5431d6c7111632c6cb7013b7efd', 1)
// call checkoutcome on commitments
instance.checkOutcome('0x0121452db83fd9c77975fd5647f8cc6a8223c5431d6c7111632c6cb7013b7efd')
```
