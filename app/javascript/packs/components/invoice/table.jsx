import humanize from "string-humanize";
import React from "react";
import { sortCollator } from "../../lib/formatters";
import TableRow from "./table_row";

const Table = function(props) {
  const { invoice } = props;
  const headers = [];

  invoice.activity_items.forEach(activity_item => {
    Object.keys(activity_item.cells).forEach(state_or_formula => {
      if (!headers.includes(state_or_formula)) {
        headers.push(state_or_formula);
      }
    });
  });

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
          {headers.map(key => (
            <th key={key} title={key}>
              {humanize(key)}
            </th>
          ))}
          <th>Activity</th>
        </tr>
      </thead>
      <tbody>
        {invoice.activity_items.map(function(row, i) {
          return (
            <TableRow
              key={[row.activity.code, i].join("-")}
              row={row}
              headers={headers}
            />
          );
        })}
      </tbody>
    </table>
  );
};

export default Table;
