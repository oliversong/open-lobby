var BillOracle = artifacts.require("OracleInterface");

module.exports = function(deployer) {
    deployer.deploy(BillOracle);
};
