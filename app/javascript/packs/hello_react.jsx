// Run this example by adding <%= javascript_pack_tag 'hello_react' %> to the head of your layout file,
// like app/views/layouts/application.html.erb. All it does is render <div>Hello React</div> at the bottom
// of the page.


import "babel-polyfill"

import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'

const Hello = props => (
  <div>Hello {props.name}!</div>
)

Hello.defaultProps = {
  name: 'David'
}

Hello.propTypes = {
  name: PropTypes.string
}

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
    <div>
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
  return (
    <div>
      <a name="{name}-{formatted_date}"></a>
      <h2>{name} at {formatted_date}</h2>
      org unit(s): {props.invoice.orgunit_ext_id} <br />
      date range: {props.invoice.period} <br />
      periods: {props.invoice.period} <br />
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
  return (
    <table className="table invoice num-span-table table-striped">
      <thead>
        <tr>

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
