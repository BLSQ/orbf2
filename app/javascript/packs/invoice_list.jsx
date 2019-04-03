import React from "react";
import humanize from "string-humanize";
import PropTypes from "prop-types";
import MultiSelectDropdown from "./multi_select_dropdown";
import { Invoice } from "./invoice";

const mapPeriods = invoices => {
  return [...new Set(invoices.map(invoice => invoice.period))];
};

const mapPackages = invoices => {
  return [...new Set(invoices.map(invoice => humanize(invoice.code)))];
};

const mapOrgunits = invoices => {
  return [...new Set(invoices.map(invoice => invoice.orgunit_ext_id))];
};

class InvoiceList extends React.Component {
  constructor(props) {
    super(props);
    const periods = mapPeriods(props.invoices);
    const packages = mapPackages(props.invoices);
    const orgunits = mapOrgunits(props.invoices);
    this.state = {
      periods,
      allPeriods: periods,
      packages,
      allPackages: packages,
      orgUnits: [orgunits[0]],
      allOrgUnits: orgunits,
    };
  }

  periodsChanged = periods => {
    this.setState({ periods });
  };

  packagesChanged = packages => {
    this.setState({ packages });
  };

  orgUnitsChanged = orgUnits => {
    this.setState({ orgUnits });
  };

  render() {
    const {
      allPeriods,
      periods,
      allPackages,
      packages,
      allOrgUnits,
      orgUnits,
    } = this.state;

    const { invoices } = this.props;

    const filteredInvoices = invoices.filter(invoice => {
      return (
        periods.includes(invoice.period) &&
        packages.includes(humanize(invoice.code)) &&
        orgUnits.includes(invoice.orgunit_ext_id)
      );
    });

    return [
      <MultiSelectDropdown
        name="Periods"
        names={allPeriods}
        selected={periods}
        optionsChanged={this.periodsChanged}
        key="periods"
      />,
      <MultiSelectDropdown
        name="Org Units"
        names={allOrgUnits}
        selected={orgUnits}
        optionsChanged={this.orgUnitsChanged}
        key="orgUnits"
      />,
      <MultiSelectDropdown
        name="Packages"
        names={allPackages}
        selected={packages}
        optionsChanged={this.packagesChanged}
        key="packages"
      />,
      filteredInvoices.map((invoice, i) => {
        const key = [invoice.orgunit_ext_id, invoice.period, invoice.code].join(
          "-",
        );
        return <Invoice key={key} invoice={invoice} />;
      }),
    ];
  }
}

InvoiceList.propTypes = {
  invoices: PropTypes.array,
};

export default InvoiceList;
