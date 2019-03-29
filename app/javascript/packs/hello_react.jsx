// Run this example by adding <%= javascript_pack_tag 'hello_react' %> to the head of your layout file,
// like app/views/layouts/application.html.erb. All it does is render <div>Hello React</div> at the bottom
// of the page.


import "babel-polyfill";

import React from 'react';
import ReactDOM from 'react-dom';
import PropTypes from 'prop-types';
import Button from '@material-ui/core/Button';
import InvoiceList from './invoice_list';

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


const getJSON = async function(url) {
  const response = await fetch(url);
  const json = await response.json();
  return json;
};

const fetchIt = async function() {
  // const response = await getJSON("also_liberia.json");
  const url = "also_liberia.json";
  const response = await getJSON(url);
  ReactDOM.render(
    <InvoiceList key="list" invoices={response.invoices} />,
    document.getElementById('root')
  );
};

// document.addEventListener('DOMContentLoaded', async () => {
//   const node = document.getElementById('root');
//   const url = node.getAttribute('data-url');
//   const jobData = await getJSON(url);
//   const simulationData = await getJSON(jobData.data.attributes.resultUrl);

//   ReactDOM.render(
//     <InvoiceList key="list" invoices={simulationData.invoices} />,
//     node
//   );
// });

// document.addEventListener('DOMContentLoaded', () => {
//   const response = JSON.parse(document.getElementById("the-data").innerHTML);
//   ReactDOM.render(
//     <InvoiceList key="list" invoices={response.invoices} />,
//     document.getElementById('root')
//   );
// });

document.addEventListener('DOMContentLoaded', () => {
    ReactDOM.render(
        <FetchButton />,
        document.getElementById('js-fetch-button')
    );
});
