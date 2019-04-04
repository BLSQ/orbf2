import humanize from "string-humanize";
import React from "react";

const ExplanationRow = function(props) {
  return (
    <tr key={`explanation-${props.header}`}>
      <td colSpan={props.rowSpan}>
        <div className="col-sm-6">
          <h3>{humanize(props.header)}</h3>
          <ul key="bla" className="col-sm-6">
            <li>{props.rowData.key}</li>
            <li>
              <code>{props.rowData.key}</code>
            </li>
            {props.rowData.dhis2_data_element && (
              <li>{props.rowData.expression}</li>
            )}
            {props.rowData.state && (
              <li>
                Mapping : {props.rowData.state.ext_id} -{" "}
                {props.rowData.state.kind} - {props.rowData.state.ext_id}
              </li>
            )}
            {props.rowData.dhis2_data_element && (
              <li>{props.rowData.dhis2_data_element}</li>
            )}
            {props.rowData.expression && props.rowData.dhis2_data_element && (
              <>
                <h3>Step by step explanations</h3>
                <pre>
                  {`${props.header} = ${props.rowData.instantiated_expression}`}
                </pre>
                <pre>{`${props.header} = ${props.rowData.substituted}`}</pre>
                <pre>{`${props.header} = ${props.rowData.solution}`}</pre>
              </>
            )}
          </ul>
        </div>
      </td>
    </tr>
  );
};

export default ExplanationRow;
