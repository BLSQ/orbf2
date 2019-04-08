import humanize from "string-humanize";
import React from "react";

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

export default TotalItems;
