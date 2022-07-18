import React, { Component, useContext } from "react";
import moment from 'moment';
import classNames from 'classnames';
import { ethers } from 'ethers';
import { UserContext } from './App';

import './styles/Bill.css';

const OutcomesEnum = ['In Progress', 'Became Law', 'Rejected'];
const dateFormat = 'MMM D, YYYY';

const parseCommitmentsData = (coms) => {
  let totalSupporting = 0
  let peopleSupporting = 0
  let totalAgainst = 0
  let peopleAgainst = 0
  coms.forEach((c) => {
    if (c.inSupport) {
      totalSupporting += c.amount;
      peopleSupporting += 1;
    } else {
      totalAgainst += c.amount;
      peopleAgainst += 1;
    }
  })

  return {
    totalSupporting,
    peopleSupporting,
    totalAgainst,
    peopleAgainst,
  };
}

const CommitmentStats = (props) => (
  <div className="Commitments">
    <div className="Commitments-supporting">
      <div className="Commitments-totalSupporting">{ethers.utils.formatEther(props.totalSupporting)} eth</div>
      <div className="Commitments-countSupporting"><b>{props.peopleSupporting}</b> supporting</div>
    </div>
    <div className="Commitments-against">
      <div className="Commitments-totalAgainst">{ethers.utils.formatEther(props.totalAgainst)} eth</div>
      <div className="Commitments-countAgainst"><b>{props.peopleAgainst}</b> against</div>
    </div>
  </div>
)


const parseYourCommitment = (coms, userAddress) => {
  if (userAddress) {
    const userCommitments = coms.filter((c) => c.user == userAddress);
    if (userCommitments.length) {
      return {
        inSupport: userCommitments[0].inSupport,
        amount: userCommitments[0].amount
      };
    }
  }
};

class PlaceCommitment extends Component {
  constructor(props) {
    super(props);
    this.state = {
      amount: 0,
      inSupport: false,
    };

    this.handleChange = this.handleChange.bind(this);
    this.handleChangeCheckbox = this.handleChangeCheckbox.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  handleChange(event) {
    this.setState({amount: event.target.value});
  }

  handleChangeCheckbox() {
    this.setState({inSupport: !this.state.inSupport});
  }

  async handleSubmit() {
    const amount = ethers.utils.parseUnits(this.state.amount, 'gwei');
    let txn = await this.props.cc.placeCommitment(amount, this.props.billId, this.state.inSupport);
    alert('Commitment placed');
  }

  render() {
    return (
      <div className="PlaceCommitment">
      <div>Amount <input type="number" placeholder="100 gwei" value={this.state.amount} onChange={this.handleChange} /></div>
        <div>In Support <input type="checkbox" onChange={this.handleChangeCheckbox} value={this.state.inSupport} /></div>
        <button className="PlaceCommitment-button" onClick={this.handleSubmit}>Place Commitment</button>
      </div>
    );
  }
}

const YourCommitment = (props) => {
  if (props.details) {
    return (
      <div className="YourCommitment">
        <div>Your Commitment: {ethers.utils.formatEther(props.details.amount)} eth {props.details.inSupport ? "in support" : "against"}.</div>
      </div>
    );
  } else {
    return (
      <div className="YourCommitment"><PlaceCommitment billId={props.billId } cc={props.cc} /></div>
    );
  }
};

const Bill = (props) => (
  <div className={classNames('Bill', {
    'Bill--pending': props.outcome == 0,
    'Bill--becameLaw': props.outcome == 1,
    'Bill--rejected': props.outcome == 2,
  })}>
    <div className="Bill-info">
      <div className="Bill-title">{props.title}</div>
      <div className="Bill-metadata">
        <div className="Bill-sponsor">Sponsor: {props.sponsor}</div>
        <div className="Bill-number">Legislation Number: {props.legislationNumber}</div>
        <div className="Bill-id">ID: {props.id}</div>
        <div className="Bill-sponsorAddress">Sponsor Address: {props.sponsorAddress}</div>
        <div className="Bill-doi">Date of Introduction: {moment(props.dateOfIntroduction).format(dateFormat)}</div>
        <div className="Bill-latestAction">Latest Action: {props.latestAction} on {moment(props.latestActionDate).format(dateFormat)}</div>
        <div className="Bill-committees">Committees: {props.committees || "None"}</div>
        <div className="Bill-amends">Amends: {props.amendsBill || "None"}</div>
      </div>
      <div className="Bill-outcome">{OutcomesEnum[props.outcome]}</div>
    </div>
    <div className="Bill-commitments">
      <CommitmentStats {...parseCommitmentsData(props.commitments)} />
      <YourCommitment billId={props.id} details={parseYourCommitment(props.commitments, useContext(UserContext))} cc={props.cc} />
    </div>
  </div>
)

export default Bill;
