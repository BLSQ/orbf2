import "babel-polyfill";

import React from "react";
import ReactDOM from "react-dom";
import Loader from "./components/loader";

// This contains the kick-off point for an asynchronous simulation:
//
//       app/views/setup/invoices/async_invoice.html.erb
//
// Will include this file, it will also render a root element with the
// URL to poll in it as a data-element.
//
// On load that page will create the `Loader` component which will
// poll that URL every 1 second, and once we have a payload URL to a
// S3 blob, we will fetch that and create the various invoices.
//
document.addEventListener("DOMContentLoaded", async () => {
  const node = document.getElementById("root");
  const url = node.getAttribute("data-url");

  ReactDOM.render(<Loader url={url} />, node);
});
