import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import classNames from 'classnames';
import { withStyles } from '@material-ui/core/styles';
import Input from '@material-ui/core/Input';
import InputLabel from '@material-ui/core/InputLabel';
import MenuItem from '@material-ui/core/MenuItem';
import FormControl from '@material-ui/core/FormControl';
import ListItemText from '@material-ui/core/ListItemText';
import Select from '@material-ui/core/Select';
import Checkbox from '@material-ui/core/Checkbox';
import Chip from '@material-ui/core/Chip';
import List from '@material-ui/core/List';
import ListItem from '@material-ui/core/ListItem';

const styles = theme => ({
  root: {
    display: 'flex',
    flexWrap: 'wrap',
  },
  formControl: {
    margin: theme.spacing.unit,
    minWidth: 200,
    maxWidth: 320,
  },
  chips: {
    display: 'flex',
    flexWrap: 'wrap',
  },
  chip: {
    margin: theme.spacing.unit / 10,
  },
  noLabel: {
    marginTop: theme.spacing.unit * 3,
  },
});


class PeriodSelector extends React.Component {
  constructor(props) {
    super(props);
  }

  handleChange = event => {
    this.props.optionsChanged(event.target.value);
  };

  handleDelete = deletedName => () => {
    this.props.optionsChanged(this.props.selected.filter(name => name != deletedName));
  };

  render() {
    const {classes} = this.props;
    return (
      <FormControl className={classes.formControl}>
        <InputLabel htmlFor="select-periods">Periods</InputLabel>
        <Select
          multiple
          value={this.props.selected}
          onChange={this.handleChange}
          input={<Input id="select-periods" />}
          >
          {this.props.names.map(name => (
            <MenuItem key={name} value={name}>
              {name}
            </MenuItem>
          ))}
      </Select>
        <List>
        {this.props.selected.map(value => (
          <ListItem className={classes.chips}>
            <Chip key={value} label={value} onDelete={this.handleDelete(value)} className={classes.chip} />
          </ListItem>
        ))}
      </List>
        </FormControl>
    );
  }
}
export default withStyles(styles, { withTheme: true })(PeriodSelector);
