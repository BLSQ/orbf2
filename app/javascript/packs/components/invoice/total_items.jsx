import humanize from "string-humanize";
import React from "react";
import { withStyles } from "@material-ui/core/styles";
import classNames from "classnames";
import ExplanationSteps from "./explanation_steps";

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
    borderBottom: `1px solid ${selectedColor}`,
  },
});

class TotalItem extends React.Component {
  state = {
    selected: false,
  };

  cellClicked = () => {
    this.setState({ selected: !this.state.selected });
  };

  render() {
    const { classes, item } = this.props;
    let value = item.solution;
    if (item.not_exported) {
      value = <del>{value}</del>;
    }
    return (
      <>
        <div className="container">
          <div className="col-md-4">
            <b>{humanize(item.formula)}</b>:
          </div>
          <div
            className={classNames(
              "col-md-3",
              item.is_output ? "formula-output" : "",
              this.state.selected ? classes.selected : null,
            )}
            onClick={this.cellClicked}
          >
            {this.state.selected && (
              <i
                className={classNames(
                  "fa fa-info-circle",
                  classes.selectedIcon,
                )}
              />
            )}
            <span
              className={classNames("num-span", {
                [classes.selectedSpan]: this.state.selected,
              })}
            >
              {value}
            </span>
          </div>
        </div>
        {this.state.selected && (
          <div>
            <dl className="dl-horizontal">
              <dt>Name</dt>
              <dd>{humanize(item.formula)}</dd>
              <dt>Key</dt>
              <dd>{item.key}</dd>
              <dt>Data element out</dt>
              <dd>{item.is_output}</dd>
            </dl>
            <div className="col-md-10">
              <div>
                <ExplanationSteps item={item} />
              </div>
            </div>
          </div>
        )}
      </>
    );
  }
}

const TotalItems = props => {
  if ((props.items || []).length == 0) {
    return null;
  }
  return props.items.map((item, i) => (
    <TotalItem item={item} key={`total-item${i}`} classes={props.classes} />
  ));
};

export default withStyles(cellStyles)(TotalItems);
