import humanize from "string-humanize";
import React from "react";
import { sortCollator } from "../../lib/formatters";
import TableRow from "./table_row";

const Table = function(props) {
  const invoice = props.invoice;
  let headers = {};
  if (invoice.activity_items[0]) {
    headers = invoice.activity_items[0].cells || {};
  }
  let rows = invoice.activity_items;
  rows = rows.sort((a, b) =>
    sortCollator.compare(a.activity.code, b.activity.code),
  );
  // TODO:
  // - new_setup_project_formula_mapping_path
  return (
    <table className="table invoice num-span-table table-striped">
      <thead>
        <tr>
          {Object.keys(headers).map(function(key) {
            return (
              <th key={key} title={key}>
                {humanize(key)}
              </th>
            );
          })}
          <th>Activity</th>
        </tr>
      </thead>
      <tbody>
        {invoice.activity_items.map(function(row, i) {
          return <TableRow key={[row.activity.code, i].join("-")} row={row} />;
        })}
      </tbody>
    </table>
  );
};

export default Table;
