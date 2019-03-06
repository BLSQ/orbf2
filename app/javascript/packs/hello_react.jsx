// Run this example by adding <%= javascript_pack_tag 'hello_react' %> to the head of your layout file,
// like app/views/layouts/application.html.erb. All it does is render <div>Hello React</div> at the bottom
// of the page.


import "babel-polyfill"

import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'

const locale = undefined;

// Used for the natural sorting, a collator is suggested to be used for large arrays.
// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/localeCompare#Performance
const collator = new Intl.Collator(locale, {numeric: true, sensitivity: 'base'});

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/NumberFormat
const numberFormatter = new Intl.NumberFormat(locale, { minimumFractionDigits: 2, maximumFractionDigits: 2, useGrouping: false});

// Poor man's version of Rails's humanize
const humanize = (string) =>
      (string || "").
      replace("_", " ").
      split(" ").
      map(s => s.charAt(0).toUpperCase() + s.slice(1)).join(" ")

const FetchButton = function(props) {
  function handleClick(e) {
    var randomColor = "#"+((1<<24)*Math.random()|0).toString(16);
    document.getElementById("color").style.backgroundColor = randomColor;

    ReactDOM.render(
      <InvoiceList invoices={[]} />,
      document.getElementById('root')
    );
    fetchIt();
  }

  return (
    <div className="pull-right">
      <i id="color"></i>
      <button onClick={handleClick}>
        Fetchez la vache!
      </button>
    </div>
  )

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
  )
};

const Solution = function(props) {
    const safeData = (props.rowData || {})
    const formattedSolution = numberFormatter.format(safeData.solution);
    if (safeData.not_exported) {
        return <del>{formattedSolution}</del>
    } else {
        return <>{formattedSolution}</>
    }
}

const TableRow = function(props) {
    var row = props.row;
    // TODO:
    // - Rounded for display
    const isInput = (rowData) =>
          (rowData || {}).is_input
    const isOutput = (rowData) =>
          (rowData || {}).is_output
    const isFormula = function(rowData) {
        var safeData = (rowData || {})
        return !!safeData.expression && !!safeData.dhis2_data_element
    }

    const classForRowData = function(rowData) {
        if (isInput(rowData))
            return "formula-input"
        if (isOutput(rowData))
            return "formula-output"
        return ""
    }
    const solution = function(rowData) {

    }
  return (
    <tr>
      {Object.keys(row.cells).map(function(key, index) {
          return <td className={classForRowData(row.cells[key])}>
              <span className="num-span" title={key}>
                    <Solution rowData={row.cells[key]} />
                  </span>
          </td>
       })}
      <td>{row.activity.name}</td>
    </tr>
  )
}

const invoiceKey = function(invoice) {
    return [invoice.orgunit_ext_id, invoice.period, invoice.code].join("-");
}

const Table = function(props) {
  var cells;
  var invoice = props.invoice;
  if(invoice.activity_items[0]) {
    cells = invoice.activity_items[0]["cells"]
  }
  const rowKey = function(invoice, row, i) {
    return [invoiceKey(invoice), row.activity.code, i].join("-");
  }
    let headers = {};
    if (invoice.activity_items[0]) {
        headers = invoice.activity_items[0].cells || {};
    }
    console.log(headers)
    let rows = invoice.activity_items;
    rows = rows.sort((a,b) =>
                     collator.compare(a.activity.code, b.activity.code)
                    )
    // TODO:
    // - new_setup_project_formula_mapping_path
  return (
    <table className="table invoice num-span-table table-striped">
      <thead>
        <tr>
          {Object.keys(headers).map(function(key) {
              return <th title={key}>{humanize(key)}</th>;
          })}
          <th>Activity</th>
        </tr>
      </thead>
      <tbody>
        {invoice.activity_items.map(function(row,i) {
           return <TableRow key={rowKey(invoice,row, i)} row={row} />
         })}
      </tbody>
    </table>
  )
}

const Invoice = function(props) {
  return (
    <div>
      <InvoiceHeader invoice={props.invoice} />
      <Table invoice={props.invoice} />
    </div>
  )
}

const InvoiceList = function(props) {
  const numbers = props.numbers;

  const invoices = props.invoices.map((invoice) =>
    <Invoice key={invoiceKey(invoice)} invoice={invoice} />
  );
  return (
    <div>
      {invoices}
    </div>
  );
}

const getJSON = async function(url) {
  const response = await fetch(url);
  const json = await response.json();
  return json;
};

const fetchIt = async function() {
  const response = await getJSON("cameroon-response-wx4w.json");
  ReactDOM.render(
    <InvoiceList invoices={response.invoices} />,
    document.getElementById('root')
  );
};

document.addEventListener('DOMContentLoaded', () => {
    ReactDOM.render(
        <FetchButton />,
        document.getElementById('js-fetch-button')
    );
});
