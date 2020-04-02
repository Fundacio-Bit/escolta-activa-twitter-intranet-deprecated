import React from 'react'
import PropTypes from 'prop-types'
import { FormGroup, FormControl, ControlLabel, Button } from 'react-bootstrap'

import axios from 'axios'

import MonthPickerInput from 'react-month-picker-input'
import 'react-month-picker-input/dist/react-month-picker-input.css'

const urlBase = `http://${window.location.hostname}:${window.location.port}`

class FormBrandMonth extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      brandList: [],
      date: new Date(),
    }
    this.handleBrandChange = this.handleBrandChange.bind(this)
    this.handleMonthChange = this.handleMonthChange.bind(this)
    this.searchButton = this.searchButton.bind(this)
  }

  // Cargamos las brands
  // -------------------
  componentDidMount() {
    let request = '/rest_utils/brands'

    axios.get(`${urlBase}${request}`)
      .then((response) => {
        let options = []
        var brandList = response.data.results
        options.push(<option value={'-1'} key={'-1'}>-- Triar --</option>)
        brandList.forEach((brand) => {
          options.push(<option value={brand} key={brand}>{brand.charAt(0).toUpperCase() + brand.slice(1)}</option>)
        })
        this.setState({
          brandList: options
        })
      })
      .catch((error) => {
        alert(error)
      })
  }

  handleBrandChange(e) {
      this.props.onSelectBrand(e.target.value)
  }

  handleMonthChange(e) {
    this.props.onSelectMonth(e)
  }

  searchButton() {
    this.props.onSearchButton()
  }

  render() {

    return (
      <div>
        <form className="well form-inline">
          <FormGroup controlId="formBrand">
            <ControlLabel>&nbsp;Marca&nbsp;</ControlLabel>
            <FormControl componentClass="select" placeholder="select" onChange={this.handleBrandChange} >
              {this.state.brandList}
            </FormControl>
          </FormGroup>
          <ControlLabel>&nbsp;Mes&nbsp;</ControlLabel>
          <FormGroup controlId="formMonthPicker">
            <MonthPickerInput
              onChange={this.handleMonthChange}
              year = {(new Date()).getFullYear()}
              month = {(new Date()).getMonth()}
              lang='ca'
              i18n={{
                'monthFormat': 'long',
                'dateFormat': {'ca': 'YY/MM'},
                'monthNames': {
                  'ca': [
                    'Gener',
                    'Febrer',
                    'Març',
                    'Abril',
                    'Maig',
                    'Juny',
                    'Juliol',
                    'Agost',
                    'Setembre',
                    'Octubre',
                    'Novembre',
                    'Desembre'
                  ]
                }
              }}
            />
          </FormGroup>
          &nbsp;
          <Button onClick={this.searchButton}>Cercar</Button>
        </form>
      </div>
    )
  }
}

FormBrandMonth.propTypes = {
  onSelectBrand: PropTypes.func.isRequired,
  onSelectMonth: PropTypes.func.isRequired,
  onSearchButton: PropTypes.func.isRequired
}

export default FormBrandMonth
