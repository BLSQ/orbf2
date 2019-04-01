import React from "react";
import Table from "@material-ui/core/Table";
import humanize from "string-humanize";
import classNames from "classnames";
import { withStyles } from "@material-ui/core/styles";
import { numberFormatter, sortCollator } from "./lib/formatters";

const cellStyles = theme => ({
  selected: {
    fontWeight: "bold",
    backgroundColor: "orange",
  },
});

const Cell = withStyles(cellStyles)(function(props) {
  const isInput = rowData => (rowData || {}).is_input;
  const isOutput = rowData => (rowData || {}).is_output;
  const isFormula = function(rowData) {
    const safeData = rowData || {};
    return !!safeData.expression && !!safeData.dhis2_data_element;
  };
  const { classes } = props;
  const classForRowData = function(rowData) {
    if (isInput(rowData)) return "formula-input";
    if (isOutput(rowData)) return "formula-output";
    return "";
  };
  const cellClicked = (event, header) => {
    props.cellClicked(props.header);
  };
  return (
    <td
      onClick={cellClicked}
      className={classNames(
        classForRowData(props.rowData),
        props.selected ? classes.selected : null,
      )}
    >
      <span className="num-span" title={props.header}>
        <Solution rowData={props.rowData} />
      </span>
    </td>
  );
});

const Solution = function(props) {
  const safeData = props.rowData || {};
  const formattedSolution = numberFormatter.format(safeData.solution);
  return (
    <>
      {parseFloat(formattedSolution) != parseFloat(safeData.solution) && (
        <span
          title={`Rounded for ${safeData.solution}`}
          className="text-danger"
          role="button"
        >
          *
        </span>
      )}

      {safeData.not_exported ? (
        <del>{formattedSolution}</del>
      ) : (
        formattedSolution
      )}
    </>
  );
};

const SelectedCell = function(props) {
  return (
    <tr key={`explanation-${props.header}`}>
      <td colSpan={props.rowSpan}>
        <div className="col-sm-6">
          <h3>{humanize(props.header)}</h3>
          <ul key="bla" className="col-sm-6">
            <li>{props.rowData.key}</li>
            <li>
              <code>{props.rowData.key}</code>
            </li>
            {props.rowData.dhis2_data_element && (
              <li>{props.rowData.expression}</li>
            )}
            {props.rowData.state && (
              <li>
                Mapping : {props.rowData.state.ext_id} -{" "}
                {props.rowData.state.kind} - {props.rowData.state.ext_id}
              </li>
            )}
            {props.rowData.dhis2_data_element && (
              <li>{props.rowData.dhis2_data_element}</li>
            )}
            {props.rowData.expression && props.rowData.dhis2_data_element && (
              <>
                <h3>Step by step explanations</h3>
                <pre>
                  {`${props.header} = ${props.rowData.instantiated_expression}`}
                </pre>
                <pre>{`${props.header} = ${props.rowData.substituted}`}</pre>
                <pre>{`${props.header} = ${props.rowData.solution}`}</pre>
              </>
            )}
          </ul>
        </div>
      </td>
    </tr>
  );
};

class BSTableRow extends React.Component {
  constructor(props) {
    super(props);
  }

  cellClicked = cellKey => {
    if (this.state.selectedHeader === cellKey) {
      this.setState({
        selectedHeader: null,
        selectedCell: null,
      });
    } else {
      this.setState({
        selectedHeader: cellKey,
        selectedCell: this.props.row.cells[cellKey],
      });
    }
  };

  state = {
    collapsedRow: false,
    selectedCell: null,
  };

  render() {
    const colSpan = Object.keys(this.props.row.cells).length + 1;
    return (
      <>
        <tr key={"row-data"}>
          {Object.keys(this.props.row.cells).map((key, index) => {
            return (
              <Cell
                key={key}
                cellClicked={this.cellClicked}
                header={key}
                selected={key == this.state.selectedHeader}
                rowData={this.props.row.cells[key]}
              />
            );
          })}
          <td>{this.props.row.activity.name}</td>
        </tr>
        {this.state.selectedCell ? (
          <SelectedCell
            key="ding"
            header={this.state.selectedHeader}
            rowData={this.state.selectedCell}
            rowSpan={colSpan}
          />
        ) : null}
      </>
    );
  }
}

const BSTable = function(props) {
  const invoice = props.invoice;
  let headers = {};
  if (invoice.activity_items[0]) {
    headers = invoice.activity_items[0].cells || {};
  }
  let rows = invoice.activity_items;
  rows = rows.sort((a, b) =>
    sortCollator.compare(a.activity.code, b.activity.code),
  );
  // TODO:
  // - new_setup_project_formula_mapping_path
  return (
    <table className="table invoice num-span-table table-striped">
      <thead>
        <tr>
          {Object.keys(headers).map(function(key) {
            return (
              <th key={key} title={key}>
                {humanize(key)}
              </th>
            );
          })}
          <th>Activity</th>
        </tr>
      </thead>
      <tbody>
        {invoice.activity_items.map(function(row, i) {
          return (
            <BSTableRow key={[row.activity.code, i].join("-")} row={row} />
          );
        })}
      </tbody>
    </table>
  );
};

const TotalItems = function(props) {
  if ((props.items || []).length == 0) {
    return null;
  }
  return props.items.map(function(item, i) {
    let value = item.solution;
    if (item.not_exported) {
      value = <del>{value}</del>;
    }
    return (
      <div key={`total-item${i}`} className="container">
        <div className="col-md-4">
          <b>{humanize(item.formula)}</b> :
        </div>
        <div className={`col-md-3 ${item.is_output ? "formula-output" : ""}`}>
          {value}
        </div>
      </div>
    );
  });
};

const InvoiceHeader = function(props) {
  const name = props.invoice.code;
  const formatted_date = props.invoice.period;
  const code = props.invoice.code;
  return (
    <div
      className="invoice-container"
      data-period={props.invoice.period}
      data-orgunit={props.invoice.orgunit_ext_id}
      data-code={props.invoice.code}
    >
      <a name={`${name}-${formatted_date}`} />
      <h2>
        <span>{humanize(code)}</span> -
        <span title={props.invoice.orgunit_ext_id}> {humanize(name)} </span>
        <span className="pull-right">
          <i className="fa fa-calendar" /> {props.invoice.period}
        </span>
      </h2>
    </div>
  );
};

export const Invoice = function(props) {
  return [
    <InvoiceHeader key="header" invoice={props.invoice} />,
    <BSTable key="invoice" invoice={props.invoice} />,
    <TotalItems key="total-items" items={props.invoice.total_items} />,
  ];
};
