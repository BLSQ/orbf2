// Run this example by adding <%= javascript_pack_tag 'hello_react' %> to the head of your layout file,
// like app/views/layouts/application.html.erb. All it does is render <div>Hello React</div> at the bottom
// of the page.


import "babel-polyfill";

import React from 'react';
import ReactDOM from 'react-dom';
import PropTypes from 'prop-types';
import Button from '@material-ui/core/Button';
import Collapse from '@material-ui/core/Collapse';
import classNames from 'classnames';
import humanize from 'string-humanize';
import InvoiceList from './invoice_list';
const locale = undefined;
import { withStyles } from '@material-ui/core/styles';

import Table from '@material-ui/core/Table';
import TableBody from '@material-ui/core/TableBody';
import TableCell from '@material-ui/core/TableCell';
import TableHead from '@material-ui/core/TableHead';
import TableRow from '@material-ui/core/TableRow';
import Paper from '@material-ui/core/Paper';

// Used for the natural sorting, a collator is suggested to be used for large arrays.
// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/localeCompare#Performance
const collator = new Intl.Collator(locale, {numeric: true, sensitivity: 'base'});

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/NumberFormat
const numberFormatter = new Intl.NumberFormat(locale, { minimumFractionDigits: 2, maximumFractionDigits: 2, useGrouping: false});

class FetchButton extends React.Component {

    handleClick = event => {
        var randomColor = "#"+((1<<24)*Math.random()|0).toString(16);
        document.getElementById("color").style.backgroundColor = randomColor;

        ReactDOM.render(
          <InvoiceList key={"list"} invoices={[]} />,
            document.getElementById('root')
        );
        fetchIt();
    };

    render() {
        return (
            <div className="pull-right">
                <i id="color"></i>
                <Button variant="contained" color="primary" onClick={this.handleClick}>
                Fetchez la vache!
            </Button>
                </div>
        );
    }
}

const InvoiceHeader = function(props) {
  var name = props.invoice.code;
  var formatted_date = props.invoice.period;
  var code = props.invoice.code;
  return (
    <div className="invoice-container" data-period={props.invoice.period} data-orgunit={props.invoice.orgunit_ext_id} data-code={props.invoice.code}>
      <a name={name + "-" + formatted_date}></a>
      <h2><span>{humanize(code)}</span> -
        <span title={props.invoice.orgunit_ext_id}> {humanize(name)} </span>
        <span className="pull-right">
          <i className="fa fa-calendar"></i> {props.invoice.period}
        </span>
      </h2>
    </div>
  );
};

const Solution = function(props) {
  const safeData = (props.rowData || {});
  const formattedSolution = numberFormatter.format(safeData.solution);
  return (
    <>
    {(parseFloat(formattedSolution) != parseFloat(safeData.solution)) &&
     <span title={"Rounded for " + safeData.solution} className="text-danger" role="button">*</span>
    }

    {safeData.not_exported ? (
      <del>{formattedSolution}</del>
    ) : formattedSolution}
    </>
  );
}

const cellStyles = theme => ({
  selected: {
    fontWeight: 'bold',
    backgroundColor: 'orange'
  }
});

const Cell = withStyles(cellStyles)(function(props) {
  const isInput = (rowData) =>
        (rowData || {}).is_input;
  const isOutput = (rowData) =>
        (rowData || {}).is_output;
  const isFormula = function(rowData) {
    var safeData = (rowData || {});
    return !!safeData.expression && !!safeData.dhis2_data_element;
  };
  const {classes} = props;
  const classForRowData = function(rowData) {
    if (isInput(rowData))
      return "formula-input";
    if (isOutput(rowData))
      return "formula-output";
    return "";
  };
  const cellClicked = (event, header) => {
    props.cellClicked(props.header);
  };
  return <td onClick={cellClicked} className={classNames(classForRowData(props.rowData), props.selected ? classes.selected : null)}>
           <span className="num-span" title={props.header}>
             <Solution rowData={props.rowData} />
           </span>
         </td>;
});

const MaterialCell = withStyles(cellStyles)(function(props) {
  const isInput = (rowData) =>
        (rowData || {}).is_input;
  const isOutput = (rowData) =>
        (rowData || {}).is_output;
  const isFormula = function(rowData) {
    var safeData = (rowData || {});
    return !!safeData.expression && !!safeData.dhis2_data_element;
  };
  const {classes} = props;
  const classForRowData = function(rowData) {
    if (isInput(rowData))
      return "formula-input";
    if (isOutput(rowData))
      return "formula-output";
    return "";
  };
  const cellClicked = (event, header) => {
    props.cellClicked(props.header);
  };
  return <TableCell onClick={cellClicked} className={classNames(classForRowData(props.rowData), props.selected ? classes.selected : null)}>
           <span className="num-span" title={props.header}>
             <Solution rowData={props.rowData} />
           </span>
         </TableCell>;
});

const SelectedCell = function(props) {
  return <tr key={"explanation-" + props.header}>
           <td colSpan={props.rowSpan}>
             <div className="col-sm-6">
               <h3>{humanize(props.header)}</h3>
               <ul key="bla" className="col-sm-6">
                 <li>{props.rowData.key}</li>
                 <li>
                   <code>
                     {props.rowData.key}
                   </code>
                 </li>
                 {props.rowData.dhis2_data_element && (
                   <li>
                     {props.rowData.expression}
                   </li>
                 )}
                 {props.rowData.state && (
                   <li>
                     Mapping : {props.rowData.state.ext_id} - {props.rowData.state.kind}  - {props.rowData.state.ext_id}
                   </li>
                 )}
                 {props.rowData.dhis2_data_element && (
                   <li>
                     {props.rowData.dhis2_data_element}
                   </li>
                 )}
                 {(props.rowData.expression && props.rowData.dhis2_data_element) && (
                   <>
                     <h3>Step by step explanations</h3>
                     <pre>{props.header + " = " + props.rowData.instantiated_expression}</pre>
                     <pre>{props.header + " = " + props.rowData.substituted}</pre>
                     <pre>{props.header + " = " + props.rowData.solution}</pre>
                   </>
                 )}
               </ul>
             </div>
           </td>
         </tr>;
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
        selectedCell: this.props.row.cells[cellKey]
      });
    }
  }

  state = {
    collapsedRow: false,
    selectedCell: null,
  }

  render() {
    const colSpan = Object.keys(this.props.row.cells).length +1;
    return (
      <>
        <tr key={"row-data"}>
          {Object.keys(this.props.row.cells).map((key, index) => {
            return <Cell key={key}
                         cellClicked={this.cellClicked}
                         header={key}
                         selected={key == this.state.selectedHeader}
                         rowData={this.props.row.cells[key]} />;
          })}
          <td>{this.props.row.activity.name}</td>
        </tr>
        {this.state.selectedCell ?
         <SelectedCell key="ding" header={this.state.selectedHeader} rowData={this.state.selectedCell} rowSpan={colSpan} /> : null
        }
      </>
    );
  }
}

class MaterialTableRow extends React.Component {
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
        selectedCell: this.props.row.cells[cellKey]
      });
    }
  }

  state = {
    collapsedRow: false,
    selectedCell: null,
  }

  render() {
    const colSpan = Object.keys(this.props.row.cells).length +1;
    return (
      <>
        <TableRow key={"row-data"}>
          {Object.keys(this.props.row.cells).map((key, index) => {
            return <MaterialCell key={key}
                         cellClicked={this.cellClicked}
                         header={key}
                         selected={key == this.state.selectedHeader}
                         rowData={this.props.row.cells[key]} />;
          })}
          <TableCell>{this.props.row.activity.name}</TableCell>
        </TableRow>
        {this.state.selectedCell ?
         <SelectedCell key="ding" header={this.state.selectedHeader} rowData={this.state.selectedCell} rowSpan={colSpan} /> : null
        }
      </>
    );
  }
}
const invoiceKey = function(invoice) {
    return [invoice.orgunit_ext_id, invoice.period, invoice.code].join("-");
}

const MaterialTable = withStyles({})(function(props) {
  const { classes } = props;
  var invoice = props.invoice;
  const rowKey = function(invoice, row, i) {
    return [invoiceKey(invoice), row.activity.code, i].join("-");
  };
  let headers = {};
  if (invoice.activity_items[0]) {
    headers = invoice.activity_items[0].cells || {};
  }
  let rows = invoice.activity_items;
  rows = rows.sort((a,b) =>
                   collator.compare(a.activity.code, b.activity.code)
                  );
  return (
    <Paper className={classes.root}>
      <Table className={classes.table}>
        <TableHead>
          <TableRow>
            {Object.keys(headers).map(function(key) {
              return <TableCell key={key} title={key}>{humanize(key)}</TableCell>;
            })}
            <TableCell>Activity</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
        {invoice.activity_items.map(function(row,i) {
          return <MaterialTableRow key={rowKey(invoice,row, i)} row={row} />;
         })}
        </TableBody>
      </Table>
    </Paper>
  );});

const BSTable = function(props) {
  var invoice = props.invoice;
  const rowKey = function(invoice, row, i) {
    return [invoiceKey(invoice), row.activity.code, i].join("-");
  };
  let headers = {};
  if (invoice.activity_items[0]) {
    headers = invoice.activity_items[0].cells || {};
  }
  let rows = invoice.activity_items;
  rows = rows.sort((a,b) =>
                   collator.compare(a.activity.code, b.activity.code)
                    );
    // TODO:
  // - new_setup_project_formula_mapping_path
  return (
    <table className="table invoice num-span-table table-striped">
      <thead>
        <tr>
          {Object.keys(headers).map(function(key) {
            return <th key={key} title={key}>{humanize(key)}</th>;
          })}
          <th>Activity</th>
        </tr>
      </thead>
      <tbody>
        {invoice.activity_items.map(function(row,i) {
          return <BSTableRow key={rowKey(invoice,row, i)} row={row} />;
         })}
      </tbody>
    </table>
  )
}

const TotalItems = function(props) {
    if ((props.items || []).length == 0) {
        return null
    }
    return (
        props.items.map(function(item,i) {
            let value = item.solution;
            if (item.not_exported) {
                value = <del>{value}</del>
            }
            return (
              <div key={'total-item'+i} className="container">
                  <div className="col-md-4">
                    <b>{humanize(item.formula)}</b> :
                  </div>
                  <div className={`col-md-3 ${item.is_output ? "formula-output": ""}`}>
                    {value}
                  </div>
                </div>
            )}));
}

export const Invoice = function(props) {
  return (
    [
      <InvoiceHeader key="header" invoice={props.invoice} />,
      <MaterialTable key="invoice" invoice={props.invoice} />,
      <TotalItems key="total-items" items={props.invoice.total_items} />,
    ]
  );
};

const getJSON = async function(url) {
  const response = await fetch(url);
  const json = await response.json();
  return json;
};

const fetchIt = async function() {
//  const response = await getJSON("cameroon-response-wx4w.json");
  const response = await getJSON("liberia.json");
  ReactDOM.render(
    <InvoiceList key="list" invoices={response.invoices} />,
    document.getElementById('root')
  );
};

document.addEventListener('DOMContentLoaded', () => {
    ReactDOM.render(
        <FetchButton />,
        document.getElementById('js-fetch-button')
    );
});
