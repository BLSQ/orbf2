import React from "react";
import { numberFormatter } from "../../lib/formatters";

const Solution = function(props) {
  const safeData = props.rowData || {};
  const formattedSolution = numberFormatter.format(safeData.solution);
  return (
    <>
      {parseFloat(formattedSolution) != parseFloat(safeData.solution) && (
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
