import React from "react";
import Cell from "./cell";
import ExplanationRow from "./explanation_row";

class TableRow extends React.Component {
  constructor(props) {
    super(props);
  }

  cellClicked = cellKey => {
    if (this.state.selectedHeader === cellKey) {
      this.setState({
        selectedHeader: null,
        selectedCell: null,
      });
    } else {
      this.setState({
        selectedHeader: cellKey,
        selectedCell: this.props.row.cells[cellKey],
      });
    }
  };

  state = {
    collapsedRow: false,
    selectedCell: null,
  };

  render() {
    const colSpan = Object.keys(this.props.row.cells).length + 1;
    return (
      <>
        <tr key={"row-data"}>
          {Object.keys(this.props.row.cells).map((key, index) => {
            return (
              <Cell
                key={key}
                cellClicked={this.cellClicked}
                header={key}
                selected={key == this.state.selectedHeader}
                rowData={this.props.row.cells[key]}
              />
            );
          })}
          <td>{this.props.row.activity.name}</td>
        </tr>
        {this.state.selectedCell ? (
          <ExplanationRow
            key="ding"
            header={this.state.selectedHeader}
            rowData={this.state.selectedCell}
            rowSpan={colSpan}
          />
        ) : null}
      </>
    );
  }
}

export default TableRow;