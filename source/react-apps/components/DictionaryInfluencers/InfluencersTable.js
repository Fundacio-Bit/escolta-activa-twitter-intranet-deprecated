import React from 'react'
import PropTypes from 'prop-types'
import { Grid, Row, Col, Table } from 'react-bootstrap'

import HeaderColumn from './HeaderColumn'
import InfluencerRow from './InfluencerRow'


class InfluencersTable extends React.Component {
  constructor(props) {
    super(props)
  }

render() {

    const rows = []

    // Añadimos cabecera
    rows.push(
      <tr key={'header'}>
        <td style={{whiteSpace: 'nowrap'}}>
          <HeaderColumn
            onSortByColumn={this.props.onSortByColumn}
            fieldName={'influencer'}
            columnName={'influencer'}
          />
        </td>
        <td style={{whiteSpace: 'nowrap'}}>
          <HeaderColumn
            onSortByColumn={this.props.onSortByColumn}
            fieldName={'category'}
            columnName={'categoria'}
          />
        </td>
        <td style={{whiteSpace: 'nowrap'}}>
          <HeaderColumn
            onSortByColumn={this.props.onSortByColumn}
            fieldName={'subcategory'}
            columnName={'subcategoria'}
          />
        </td>
        <td style={{whiteSpace: 'nowrap'}}>
          <HeaderColumn
            onSortByColumn={this.props.onSortByColumn}
            fieldName={'creation_date'}
            columnName={'creat'}
          />
        </td>
        <td style={{whiteSpace: 'nowrap'}}>
          <HeaderColumn
            onSortByColumn={this.props.onSortByColumn}
            fieldName={'last_update'}
            columnName={'modificat'}
          />
        </td>
        <td>&nbsp;</td>
        <td>&nbsp;</td>
      </tr>
    )

    this.props.influencers.forEach((influencer) => {
      rows.push(
        <InfluencerRow
          influencer={influencer.influencer}
          category={influencer.category}
          subcategory={influencer.subcategory}
          creation_date={influencer.creation_date}
          last_update={influencer.last_update}
          key={influencer.influencer}
          onUpdateInfluencersTable={this.props.onUpdateInfluencersTable}
        />
      )
    })

    return (
      <Grid fluid>
        <Row>
          <Col md={12}>
            <p>
              S´han trobat <strong>{this.props.influencers.length}</strong> influencers.
            </p>
          </Col>
        </Row>
        <Row>
          <Table striped condensed>
            <tbody>
              {rows}
            </tbody>
          </Table>
        </Row>
      </Grid>
    )
  }
}

InfluencersTable.propTypes = {
  influencers: PropTypes.array,
  onSortByColumn: PropTypes.func,
  onUpdateInfluencersTable: PropTypes.func
}

export default InfluencersTable
