import "babel-polyfill";

import React from 'react';
import ReactDOM from 'react-dom';
import PropTypes from 'prop-types';
import Button from '@material-ui/core/Button';
import InvoiceList from './invoice_list';
import LinearProgress from '@material-ui/core/LinearProgress';
import Fade from '@material-ui/core/Fade';


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
    jsonPayload: {invoices: []}
  }

  componentWillUnmount() {
    clearInterval(this.timer);
    this.timer = null;
  }

  async fetchJSON(url) {
    const response = await fetch(url, {});
    const json = await response.json();
    return json;
  };

  async apiFetch(url) {
    const payload = await this.fetchJSON(url);
    console.table(payload.data.attributes);
    if (!payload.data.attributes.isAlive) {
      clearInterval(this.timer);
      this.fetchSimulationResult(payload.data.attributes.resultUrl);
    }
  }

  async fetchSimulationResult(url) {
    console.log("Fetching simulation: ", url);
    const payload = await this.fetchJSON(url);
    console.log(payload);
    this.setState({
      loading: false,
      jsonPayload: payload
    });
  }

  async componentDidMount() {
    const url = this.props.url;
    this.timer = setInterval(() => this.apiFetch(url), 1000);
  }

  render() {
    const { loading, jsonPayload } = this.state;
    return (
      <>
        <Fade
          in={loading}
          style={{
            transitionDelay: loading ? '800ms' : '0ms',
          }}
          unmountOnExit
        >
          <LinearProgress variant="query" />
        </Fade>,
        { !loading && (
          <InvoiceList key="list" invoices={jsonPayload.invoices} />
        )}
      </>
    );
  }
}

document.addEventListener('DOMContentLoaded', async () => {
  const node = document.getElementById('root');
  const url = node.getAttribute('data-url');
  const jobData = await getJSON(url);
  const simulationData = await getJSON(jobData.data.attributes.resultUrl);

  ReactDOM.render(
    <Loader url={url} />,
    node
  );
});
