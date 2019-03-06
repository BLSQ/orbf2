// Run this example by adding <%= javascript_pack_tag 'hello_react' %> to the head of your layout file,
// like app/views/layouts/application.html.erb. All it does is render <div>Hello React</div> at the bottom
// of the page.


import "babel-polyfill"

import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'

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
    <div class="pull-right">
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
      <h2><span>{code}</span> -
        <span title={props.invoice.orgunit_ext_id}> {name} </span>
        <span class="pull-right">
          <i class="fa fa-calendar"></i> {props.invoice.period}
        </span>
      </h2>
    </div>
  )
};

const TableRow = function(props) {
  var row = props.row;
  return (
    <tr>
      {Object.keys(row.cells).map(function(key, index) {
         return <td>{row.cells[key].solution}</td>
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
  return (
    <table className="table invoice num-span-table table-striped">
      <thead>
        <tr>
          {Object.keys(headers).map(function(key) {
              return <th>{key}</th>;
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
