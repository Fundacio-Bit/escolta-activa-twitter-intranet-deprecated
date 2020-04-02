import React from 'react'
import PropTypes from 'prop-types'


class HeaderColumn extends React.Component {
  constructor(props) {
    super(props)
  }

  orderAsc(field) {
    this.props.onSortByColumn('asc', field)
  }

  orderDesc(field) {
    this.props.onSortByColumn('desc', field)
  }

  render() {
    return (
      <div>
        <span
          className={'glyphicon glyphicon-chevron-up'}
          aria-hidden="true"
          onClick={() => this.orderAsc(this.props.fieldName)}
        />
        &nbsp;
        <strong>{this.props.columnName}</strong>
        &nbsp;
        <span
          className={'glyphicon glyphicon-chevron-down'}
          aria-hidden="true"
          onClick={() => this.orderDesc(this.props.fieldName)}
        />
      </div>
    )
  }
}

HeaderColumn.propTypes = {
  columnName: PropTypes.string,
  fieldName: PropTypes.string,
  onSortByColumn: PropTypes.func
}

export default HeaderColumn
