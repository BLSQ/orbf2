import React from "react";
import { numberFormatter } from "../../lib/formatters";

const Solution = function(props) {
  const safeData = props.rowData || {};

  let formattedSolution;
  let rounded;

  if (safeData.solution === undefined) {
    formattedSolution = "";
    rounded = false;
  } else {
    formattedSolution = numberFormatter.format(safeData.solution);
    rounded = parseFloat(formattedSolution) != parseFloat(safeData.solution);
  }

  return (
    <>
      {rounded && (
        <span
          title={`Rounded for ${safeData.solution}`}
          className="text-danger"
          role="button"
        >
          *
        </span>
      )}

      {safeData.not_exported ? (
        <del>{formattedSolution}</del>
      ) : (
        formattedSolution
      )}
    </>
  );
};

export default Solution;
