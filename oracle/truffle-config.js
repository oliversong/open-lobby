const { mnemonic, projectId }= require('./secrets.json');
const HDWalletProvider = require('@truffle/hdwallet-provider');
const NonceTrackerSubprovider = require("web3-provider-engine/subproviders/nonce-tracker")

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 7545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
    },
    goerli: {
      provider: () => {
        const wallet = new HDWalletProvider(mnemonic, `https://goerli.infura.io/v3/${projectId}`);
        const nonceTracker = new NonceTrackerSubprovider();
        wallet.engine._providers.unshift(nonceTracker);
        nonceTracker.setEngine(wallet.engine);
        return wallet;
      },
      network_id: 5,
      // gas: 29900676,
      // gasPrice: 5000000000,
    },
    rinkeby: {
      provider: () => {
        const wallet = new HDWalletProvider(mnemonic, `https://rinkeby.infura.io/v3/${projectId}`);
        const nonceTracker = new NonceTrackerSubprovider();
        wallet.engine._providers.unshift(nonceTracker);
        nonceTracker.setEngine(wallet.engine);
        return wallet;
      },
      network_id: 4,
    },
  }
};
