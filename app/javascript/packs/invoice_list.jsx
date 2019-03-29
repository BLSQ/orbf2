import React from 'react';
import ReactDOM from 'react-dom';
import PropTypes from 'prop-types';
import humanize from 'string-humanize';
import MultiSelectDropdown from './multi_select_dropdown';
import {Invoice} from './invoice';

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

  orgUnitsChanged = units => {
    this.setState({orgUnits: units});
  }

  allPeriods = invoices => {
    return [...new Set(invoices.map(invoice => invoice.period))];
  }

  allPackages = invoices => {
    return [...new Set(invoices.map(invoice => humanize(invoice.code)))];
  }

  allOrgunits = invoices => {
    return [...new Set(invoices.map(invoice => invoice.orgunit_ext_id))];
  }

  render() {
    let filteredInvoices = this.props.invoices.filter((invoice) => {
      return this.state.periods.includes(invoice.period) ||
        this.state.packages.includes(humanize(invoice.code)) ||
        this.state.orgUnits.includes(invoice.orgunit_ext_id);
    });
    const allPeriods = this.allPeriods(this.props.invoices);
    const allPackages = this.allPackages(this.props.invoices);
    const allOrgUnits = this.allOrgunits(this.props.invoices);
    const selectedPeriods = this.state.periods;
    const selectedPackages = this.state.packages;

    return ([
      <MultiSelectDropdown name="Periods"
                      names={allPeriods}
                      selected={selectedPeriods}
                      optionsChanged={this.periodsChanged}
                      key={"periods"}/>,
      <MultiSelectDropdown name="Org Units"
                      names={allOrgUnits}
                      selected={this.state.orgUnits}
                      optionsChanged={this.orgUnitsChanged}
                      key={"orgUnits"}/>,
      <MultiSelectDropdown name="Packages"
                      names={allPackages}
                      selected={selectedPackages}
                      optionsChanged={this.packagesChanged}
                      key={"packages"}/>,
      filteredInvoices.map((invoice, i) => {
        const key = [invoice.orgunit_ext_id, invoice.period, invoice.code].join("-");
        return <Invoice key={key} invoice={invoice} />;
      })
    ]);
  }
}

export default InvoiceList;
