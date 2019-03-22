import React from 'react';
import ReactDOM from 'react-dom';
import PropTypes from 'prop-types';
import PeriodSelector from './period_selector';
import {Invoice} from './hello_react';

const invoiceKey = function(invoice) {
    return [invoice.orgunit_ext_id, invoice.period, invoice.code].join("-");
}

// Poor man's version of Rails's humanize
const humanize = (string) =>
      (string || "").
      replace(/_/g, " ").
      split(" ").
      map(s => s.charAt(0).toUpperCase() + s.slice(1)).join(" ");

class InvoiceList extends React.Component {
  constructor(props) {
    super(props);
  }

  state = {
    periods: [],
    orgUnits: [],
    packages: []
  }

  periodsChanged = periods => {
    this.setState({periods: periods});
  }

  packagesChanged = periods => {
    this.setState({packages: periods});
  }

  allPeriods = invoices => {
    return [...new Set(invoices.map(invoice => invoice.period))];
  }

  allPackages = invoices => {
    return [...new Set(invoices.map(invoice => humanize(invoice.code)))];
  }

  render() {
    let filteredInvoices = this.props.invoices.filter((invoice) => {
      return this.state.periods.includes(invoice.period) ||
        this.state.packages.includes(humanize(invoice.code));
    });
    const invoices = filteredInvoices.map((invoice) => { //
      return <Invoice key={invoiceKey(invoice)} invoice={invoice} />;
    });
    const allPeriods = this.allPeriods(this.props.invoices);
    const allPackages = this.allPackages(this.props.invoices);
    const selectedPeriods = this.state.periods;
    const selectedPackages = this.state.packages;

    return ([
      <PeriodSelector names={allPeriods} selected={selectedPeriods} optionsChanged={this.periodsChanged} key={"periods"}/>,
      <PeriodSelector names={allPackages} selected={selectedPackages} optionsChanged={this.packagesChanged} key={"packages"}/>,
      <div>
        {invoices}
      </div>
    ]);
  }
}

export default InvoiceList;
