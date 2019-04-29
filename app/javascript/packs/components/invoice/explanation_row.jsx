import humanize from "string-humanize";
import React from "react";

const backgroundColor = "rgb(253, 250, 249)";

const ExplanationStep = props => (
  <pre style={{ whiteSpace: "pre-wrap" }}>{props.children}</pre>
);

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
            <>
              <h5>Step by step explanations:</h5>
              {props.rowData.expression && (
                <ExplanationStep>
                  {`${props.header} = ${props.rowData.expression}`}
                </ExplanationStep>
              )}
              <ExplanationStep>
                {`${props.header} = ${props.rowData.instantiated_expression}`}
              </ExplanationStep>
              <ExplanationStep>
                {`${props.header} = ${props.rowData.substituted}`}
              </ExplanationStep>
              <ExplanationStep>
                {`${props.header} = ${props.rowData.solution}`}
              </ExplanationStep>
            </>
          )}
        </div>
      </td>
    </tr>
  );
};

export default ExplanationRow;
