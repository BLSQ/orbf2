import "babel-polyfill";

import React from "react";
import ReactDOM from "react-dom";
import PropTypes from "prop-types";
import Button from "@material-ui/core/Button";
import LinearProgress from "@material-ui/core/LinearProgress";
import Fade from "@material-ui/core/Fade";
import InvoiceList from "./invoice_list";

// This contains the kick-off point for an asynchronous simulation:
//
//       app/views/setup/invoices/async_invoice.html.erb
//
// Will include this file, it will also render a root element with the
// URL to poll in it as a data-element.
//
// On load this page will poll that URL every 1 second, and once we
// have a payload URL to a S3 blob, we will fetch that and create the
// various invoices.
const getJSON = async function(url) {
  const response = await fetch(url);
  const json = await response.json();
  return json;
};

class Loader extends React.Component {
  constructor(props) {
    super(props);
  }

  state = {
    loading: true,
    jsonPayload: { invoices: [] },
  };

  async componentDidMount() {
    const url = this.props.url;
    this.timer = setInterval(() => this.apiFetch(url), 1000);
  }

  componentWillUnmount() {
    clearInterval(this.timer);
    this.timer = null;
  }

  async fetchJSON(url) {
    const response = await fetch(url, {});
    const json = await response.json();
    return json;
  }

  async apiFetch(url) {
    const payload = await this.fetchJSON(url);
    if (!payload.data.attributes.isAlive) {
      clearInterval(this.timer);
      this.fetchSimulationResult(payload.data.attributes.resultUrl);
    }
  }

  async fetchSimulationResult(url) {
    const payload = await this.fetchJSON(url);
    this.setState({
      loading: false,
      jsonPayload: payload,
    });
  }

  render() {
    const { loading, jsonPayload } = this.state;

    return (
      <>
        <Fade
          in={loading}
          style={{
            transitionDelay: loading ? "800ms" : "0ms",
          }}
          unmountOnExit
        >
          <LinearProgress variant="query" />
        </Fade>
        {!loading && <InvoiceList key="list" invoices={jsonPayload.invoices} />}
      </>
    );
  }
}

document.addEventListener("DOMContentLoaded", async () => {
  const node = document.getElementById("root");
  const url = node.getAttribute("data-url");

  ReactDOM.render(<Loader url={url} />, node);
});