import humanize from "string-humanize";
import React from "react";
import ExplanationSteps from "./explanation_steps";

const backgroundColor = "rgb(253, 250, 249)";

const ExplanationRow = function(props) {
  return (
    <tr key={`explanation-${props.header}`} style={{ backgroundColor }}>
      <td colSpan={props.rowSpan}>
        <div className="col-sm-9">
          <dl className="dl-horizontal">
            <dt>Name</dt>
            <dd>{humanize(props.header)}</dd>
            <dt>Key</dt>
            <dd>{props.rowData.key}</dd>

            {props.rowData.state && [
              <dt key="mapping-label">Mapping</dt>,
              <dd key="mapping-value">
                {props.rowData.state.kind} - {props.rowData.state.ext_id || ""}
              </dd>,
            ]}
            {props.rowData.dhis2_data_element && [
              <dt key="de-label">DHIS2-element</dt>,
              <dd key="de-value">{props.rowData.dhis2_data_element}</dd>,
            ]}
          </dl>

          {props.rowData.instantiated_expression && (
            <ExplanationSteps item={props.rowData} variable={props.header} />
          )}
        </div>
      </td>
    </tr>
  );
};

export default ExplanationRow;
