import React, { Component } from "react";
import { ethers } from 'ethers';
import Commitments from './contracts/Commitments.json';
import BillOracle from './contracts/BillOracle.json';
import Bill from './Bill';
import secrets from './secrets.json'

import './styles/App.css';

export const UserContext = React.createContext(null);

class App extends Component {
  constructor() {
    super();
    this.state = {
      provider: null,
      signer: null,
      commitmentsContract: null,
      oracleContract: null,
      bills: null,
      userAddress: null,
    };
  }

  parseBill(billData) {
    const [id, amendsBill, sponsor, sponsorAddress, dateOfIntroduction, committees, latestAction, latestActionDate, title, legislationNumber, outcome] = billData;
    return {
      id,
      amendsBill,
      sponsor,
      sponsorAddress,
      dateOfIntroduction: dateOfIntroduction.toNumber() * 1000,
      committees,
      latestAction,
      latestActionDate: latestActionDate.toNumber() * 1000,
      title,
      legislationNumber,
      outcome,
    };
  }

  async addCommitments(bill) {

  }

  async componentDidMount() {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    const signer = provider.getSigner();
    const userAddress = await signer.getAddress();

    const commitmentsContract = new ethers.Contract(
      secrets.commitmentsAddress, Commitments.abi, signer
    );
    const oracleContract = new ethers.Contract(
      secrets.oracleAddress, BillOracle.abi, provider
    );

    const billIds = await oracleContract.getAllBills();
    const billData = await Promise.all(billIds.map(b => oracleContract.getBill(b)));
    let bills = billData.map(b => this.parseBill(b));
    const billsCommitments = await Promise.all(bills.map(b => commitmentsContract.getBillCommitments(b.id)));

    bills = bills.map((b, i) => ({
      ...b,
      commitments: billsCommitments[i],
    }));

    this.setState({
      provider,
      signer,
      commitmentsContract,
      oracleContract,
      bills,
      userAddress,
    });
  }

  render() {
    if (!this.state.provider) {
      return (
        <div className="App">
          <h1>OpenLobby</h1>
          <h2>Connecting to Ethereum Testnet...</h2>
        </div>
      );
    }

    if (!this.state.bills) {
      return(
        <div className="App">
          <h1>OpenLobby</h1>
          <h2>Retrieving Bill Data...</h2>
        </div>
      );
    }

    return (
      <UserContext.Provider value={this.state.userAddress}>
        <div className="App">
          <h1>OpenLobby</h1>
          <div className="Bills">
            { this.state.bills.map(b => <Bill {...b} cc={this.state.commitmentsContract} />)}
          </div>
        </div>
      </UserContext.Provider>
    );
  }
}

export default App;
