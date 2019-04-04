import { withStyles } from "@material-ui/core/styles";
import classNames from "classnames";
import React from "react";
import Solution from "./solution";

const selectedColor = "rgb(254, 213, 149)";

const cellStyles = theme => ({
  selected: {
    fontWeight: "bold",
  },
  selectedIcon: {
    color: selectedColor,
    paddingRight: "5px",
  },
  selectedSpan: {
    borderBottom: `2px solid ${selectedColor}`,
  },
});

const Cell = function(props) {
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
      <span
        className={classNames("num-span", {
          [classes.selectedSpan]: props.selected,
        })}
        title={props.header}
      >
        {props.selected && (
          <i
            className={classNames("fa fa-info-circle", classes.selectedIcon)}
          />
        )}
        <Solution rowData={props.rowData} />
      </span>
    </td>
  );
};

export default withStyles(cellStyles)(Cell);
