import Table from "@material-ui/core/Table";
import TableBody from "@material-ui/core/TableBody";
import TableCell from "@material-ui/core/TableCell";
import TableHead from "@material-ui/core/TableHead";
import TableRow from "@material-ui/core/TableRow";
import Paper from "@material-ui/core/Paper";

// This is currently not in use, could be used as a drop in
// replacement for the other Table classes, which would use the
// Material UI instead of the Bootstrap UI.
//
// We could also just remove this and never speak of it again.

const MaterialCell = withStyles(cellStyles)(function(props) {
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
    <TableCell
      onClick={cellClicked}
      className={classNames(
        classForRowData(props.rowData),
        props.selected ? classes.selected : null,
      )}
    >
      <span className="num-span" title={props.header}>
        <Solution rowData={props.rowData} />
      </span>
    </TableCell>
  );
});

class MaterialTableRow extends React.Component {
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
        <BSTableRow key={"row-data"}>
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
          <TableCell>{this.props.row.activity.name}</TableCell>
        </BSTableRow>
        {this.state.selectedCell ? (
          <SelectedCell
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

const MaterialTable = withStyles({})(function(props) {
  const { classes } = props;
  const invoice = props.invoice;
  const rowKey = function(invoice, row, i) {
    return [invoiceKey(invoice), row.activity.code, i].join("-");
  };
  let headers = {};
  if (invoice.activity_items[0]) {
    headers = invoice.activity_items[0].cells || {};
  }
  let rows = invoice.activity_items;
  rows = rows.sort((a, b) =>
    collator.compare(a.activity.code, b.activity.code),
  );
  return (
    <Paper className={classes.root}>
      <Table className={classes.table}>
        <TableHead>
          <TableRow>
            {Object.keys(headers).map(function(key) {
              return (
                <TableCell key={key} title={key}>
                  {humanize(key)}
                </TableCell>
              );
            })}
            <TableCell>Activity</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {invoice.activity_items.map(function(row, i) {
            return <TableRow key={rowKey(invoice, row, i)} row={row} />;
          })}
        </TableBody>
      </Table>
    </Paper>
  );
});
