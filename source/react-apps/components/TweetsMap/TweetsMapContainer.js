import React from 'react'
import { Grid, Row, Col } from 'react-bootstrap'
import axios from 'axios'

import Title from '../_Commons/Title'
import ErrorMessage from '../_Commons/ErrorMessage'
import FormBrandMonth from '../_Commons/FormBrandMonth'
import TweetsMap from './TweetsMap'


// Base URL definition
const urlBase = `http://${window.location.hostname}:${window.location.port}`


class TweetsMapContainer extends React.Component {
  constructor() {
    super()
    this.state = {
      error: {exists: false, message: ''},
      brand: '',
      month: '',
      mapCoordinates: []
    }
    // Handlers to capture form events and other component general functions
    // should be bind here.
    this.handleSelectBrand = this.handleSelectBrand.bind(this)
    this.handleSelectMonth = this.handleSelectMonth.bind(this)
    this.handleSearchButton = this.handleSearchButton.bind(this)
    this.getCoordinates = this.getCoordinates.bind(this)
  }

  getCoordinates(){
    let request = '/rest_maps/coordinates/yearmonth/' + this.state.month + '/brand/' + this.state.brand
    axios.get(`${urlBase}${request}`)
      .then((response) => {
        if (response.data.items.length > 0 ) {
          this.setState({
            mapCoordinates: response.data.items,
            error: { exists: false, message: '' }
          })
        }
        else {
          this.setState({
            mapCoordinates: [],
            error: { exists: true, message: 'No hi ha coordenades per a aquesta cerca.' }
          })

        }

      })
      .catch(() => {
        this.setState({
          mapCoordinates: [],
          error: {
            exists: true,
            message: 'Per favor seleccioni marca i mes.' }
        })
      })
  }

  handleSelectBrand(selectedBrand) {
    this.setState({
      brand: selectedBrand
    })
  }

  // TODO: handle better the year formatting. It should not be assigned 20 directly.
  handleSelectMonth(selectedMonth) {
    this.setState({
      month: 20 + selectedMonth.replace('/', '-')
    })
  }


  handleSearchButton() {
    this.setState({
      mapCoordinates: []
    })
    this.getCoordinates()
  }
  render() {
    return (
      <Grid fluid>
        <Row>
          <Col md={12}>
            <Title name={'Mapes'} />
          </Col>
        </Row>
        <Row>
          <Col md={12}>
            <FormBrandMonth
              onSelectBrand={this.handleSelectBrand}
              month= {this.state.month}
              onSelectMonth={this.handleSelectMonth}
              onSearchButton={this.handleSearchButton}
            />
          </Col>
        </Row>
        <Row>
          <Col md={12}>
            {this.state.error.exists && <div><ErrorMessage message={this.state.error.message}/></div>}
            <TweetsMap coordinates = {this.state.mapCoordinates}/>
          </Col>
        </Row>
      </Grid>
    )
  }
}

export default TweetsMapContainer
