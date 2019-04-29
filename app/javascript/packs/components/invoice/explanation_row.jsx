import humanize from "string-humanize";
import React from "react";

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
            {props.rowData.dhis2_data_element && [
              <dt>Expression</dt>,
              <dd>{props.rowData.expression}</dd>,
            ]}
            {props.rowData.state && [
              <dt key="mapping-label">Mapping</dt>,
              <dd key="mapping-value">
                {props.rowData.state.kind} - {props.rowData.state.ext_id || "" }
              </dd>,
            ]}
            {props.rowData.dhis2_data_element && [
              <dt>DHIS2-element</dt>,
              <dd>{props.rowData.dhis2_data_element}</dd>,
            ]}
          </dl>

          {props.rowData.expression && props.rowData.dhis2_data_element && (
            <>
              <h5>Step by step explanations:</h5>
              <pre style={{ whiteSpace: "pre-wrap" }}>
                {`${props.header} = ${props.rowData.instantiated_expression}`}
              </pre>
              <pre style={{ whiteSpace: "pre-wrap" }}>
                {`${props.header} = ${props.rowData.substituted}`}
              </pre>
              <pre style={{ whiteSpace: "pre-wrap" }}>
                {`${props.header} = ${props.rowData.solution}`}
              </pre>
            </>
          )}
        </div>
      </td>
    </tr>
  );
};

export default ExplanationRow;
