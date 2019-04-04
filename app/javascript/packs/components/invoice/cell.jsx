import { withStyles } from "@material-ui/core/styles";
import classNames from "classnames";
import React from "react";
import Solution from "./solution";

const cellStyles = theme => ({
  selected: {
    fontWeight: "bold",
    backgroundColor: "orange",
  },
});

const Cell = withStyles(cellStyles)(function(props) {
  const isInput = rowData => (rowData || {}).is_input;
  const isOutput = rowData => (rowData || {}).is_output;
  const isFormula = function(rowData) {
    const safeData = rowData || {};
    return !!safeData.expression && !!safeData.dhis2_data_element;
  };
  const { classes } = props;
  const classForRowData = function(rowData) {
    if (isInput(rowData)) return "formula-input";
    if (isOutput(rowData)) return "formula-output";
    return "";
  };
  const cellClicked = (event, header) => {
    props.cellClicked(props.header);
  };
  return (
    <td
      onClick={cellClicked}
      className={classNames(
        classForRowData(props.rowData),
        props.selected ? classes.selected : null,
      )}
    >
      <span className="num-span" title={props.header}>
        <Solution rowData={props.rowData} />
      </span>
    </td>
  );
});

export default Cell;
