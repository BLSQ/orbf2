import "babel-polyfill";

import React from "react";
import ReactDOM from "react-dom";
import Loader from "./components/loader";

document.addEventListener("DOMContentLoaded", async () => {
  const node = document.getElementById("root");
  const url = node.getAttribute("data-url");

  ReactDOM.render(<Loader url={url} />, node);
});
