import React, { Component } from "react";
import { ethers } from 'ethers';
import Commitments from './contracts/Commitments.json';
import BillOracle from './contracts/BillOracle.json';
import Bill from './Bill';
import secrets from './secrets.json'

import './styles/App.css';

class App extends Component {
  constructor() {
    super();
    this.state = {
      provider: null,
      signer: null,
      commitmentsContract: null,
      oracleContract: null,
      bills: null,
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

  async componentDidMount() {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    const signer = provider.getSigner();

    const commitmentsContract = new ethers.Contract(
      secrets.commitmentsAddress, Commitments.abi, provider
    );
    const oracleContract = new ethers.Contract(
      secrets.oracleAddress, BillOracle.abi, provider
    );

    const billIds = await oracleContract.getAllBills();
    const billData = await Promise.all(billIds.map(b => oracleContract.getBill(b)));
    const bills = billData.map(d => this.parseBill(d));

    this.setState({
      provider,
      signer,
      commitmentsContract,
      oracleContract,
      bills,
    });
  }

  render() {
    if (!this.state.provider) {
      return <div className="App"><h2>Connecting to Ethereum Testnet...</h2></div>;
    }

    if (!this.state.bills) {
      return <div className="App"><h2>Retrieving Bill Data...</h2></div>;
    }

    return (
      <div className="App">
        <h1>OpenLobby</h1>
        { this.state.bills.map(b => <Bill {...b} />)}
      </div>
    );
  }
}

export default App;
