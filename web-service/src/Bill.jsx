import React, { Component } from "react";
import moment from 'moment';
import classNames from 'classnames';

import './styles/Bill.css';

const OutcomesEnum = ['Pending', 'Became Law', 'Rejected'];
const dateFormat = 'MMMM Do YYYY, h:mm:ss a';

const Bill = (props) => (
  <div className={classNames('Bill', {
    'Bill--pending': props.outcome == 0,
    'Bill--becameLaw': props.outcome == 1,
    'Bill--rejected': props.outcome == 2,
  })}>
    <div className="Bill-title">{props.title}</div>
    <div className="Bill-sponsor">Sponsor: {props.sponsor}</div>
    <div className="Bill-number">Legislation Number: {props.legislationNumber}</div>
    <div className="Bill-id">ID: {props.id}</div>
    <div className="Bill-sponsorAddress">Sponsor Address: {props.sponsorAddress}</div>
    <div className="Bill-doi">Date of Introduction: {moment(props.dateOfIntroduction).format(dateFormat)}</div>
    <div className="Bill-latestAction">Latest Action: {props.latestAction} on {moment(props.latestActionDate).format(dateFormat)}</div>
    <div className="Bill-committees">Committees: {props.committees || "None"}</div>
    <div className="Bill-amends">Amends: {props.amendsBill || "None"}</div>
    <div className="Bill-outcome">Outcome: {OutcomesEnum[props.outcome]}</div>
  </div>
)
export default Bill;
