import React from "react";
import humanize from "string-humanize";
import PropTypes from "prop-types";
import some from "lodash/some";
import uniqWith from "lodash/uniqWith";
import Grid from "@material-ui/core/Grid";
import MultiSelectDropdown from "./multi_select_dropdown";
import { Invoice } from "./invoice";

const mapPeriods = invoices => {
  const all = invoices.map(invoice => ({
    key: invoice.period,
    human: humanize(invoice.period),
  }));
  return uniqWith(all, (a, b) => a.key === b.key);
};

const mapPackages = invoices => {
  const all = invoices.map(invoice => ({
    key: invoice.code,
    human: humanize(invoice.code),
  }));

  return uniqWith(all, (a, b) => a.key === b.key);
};

const mapOrgunits = invoices => {
  const all = invoices.map(invoice => ({
    key: invoice.orgunit_ext_id,
    human: invoice.orgunit_name,
  }));

  return uniqWith(all, (a, b) => a.key === b.key);
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

  periodsChanged = periodKeys => {
    const selectedPeriods = this.state.allPeriods.filter(item =>
      periodKeys.includes(item.key),
    );
    this.setState({ periods: selectedPeriods });
  };

  packagesChanged = packageKeys => {
    const selectedPackages = this.state.allPackages.filter(item =>
      packageKeys.includes(item.key),
    );
    this.setState({ packages: selectedPackages });
  };

  orgUnitsChanged = orgUnitKeys => {
    const selectedOrgUnits = this.state.allOrgUnits.filter(item =>
      orgUnitKeys.includes(item.key),
    );
    this.setState({ orgUnits: selectedOrgUnits });
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
        some(periods, ["key", invoice.period]) &&
        some(packages, ["key", invoice.code]) &&
        some(orgUnits, ["key", invoice.orgunit_ext_id])
      );
    });
    return [
      <Grid
        container
        key="selection-grid"
        direction="row"
        justify="space-between"
        alignItems="flex-start"
      >
        <MultiSelectDropdown
          name="Periods"
          items={allPeriods}
          selected={periods}
          optionsChanged={this.periodsChanged}
          key="periods"
        />
        <MultiSelectDropdown
          name="Org Units"
          items={allOrgUnits}
          selected={orgUnits}
          optionsChanged={this.orgUnitsChanged}
          key="orgUnits"
        />
        <MultiSelectDropdown
          name="Packages"
          items={allPackages}
          selected={packages}
          optionsChanged={this.packagesChanged}
          key="packages"
        />
      </Grid>,
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
