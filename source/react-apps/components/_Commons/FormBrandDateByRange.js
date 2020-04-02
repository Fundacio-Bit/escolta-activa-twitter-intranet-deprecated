import React from 'react'
import PropTypes from 'prop-types'
import { FormGroup, FormControl, ControlLabel, Button } from 'react-bootstrap'
import DatePicker from 'react-bootstrap-date-picker'
import axios from 'axios'

const catalanDayLabels = ['Dg', 'Dl', 'Dm', 'Dc', 'Dj', 'Dv', 'Ds']
const catalanMonthLabels = ['Gener', 'Febrer', 'Març', 'Abril', 'Maig', 'Juny', 'Juliol', 'Agost', 'Setembre', 'Octubre', 'Novembre', 'Desembre']

const urlBase = `http://${window.location.hostname}:${window.location.port}`

class FormBrandDateByRange extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      brandList: []
    }
    this.handleBrandChange = this.handleBrandChange.bind(this)
    this.handleStartDateChange = this.handleStartDateChange.bind(this)
    this.handleEndDateChange = this.handleEndDateChange.bind(this)
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

  handleStartDateChange(value) {
    this.props.onSelectStartDate(value)
  }

  handleEndDateChange(value) {
    this.props.onSelectEndDate(value)
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
        <FormGroup controlId="formStartDate">
          <ControlLabel>&nbsp;Data inici&nbsp;</ControlLabel>
          <DatePicker
            value={this.props.startDate}
            onChange={this.handleStartDateChange}
            dateFormat={'YYYY-MM-DD'}
            dayLabels={catalanDayLabels}
            monthLabels={catalanMonthLabels}
            weekStartsOnMonday
          />
        </FormGroup>
        <FormGroup controlId="formEndDate">
          <ControlLabel>&nbsp;Data fi&nbsp;</ControlLabel>
          <DatePicker
            value={this.props.endDate}
            onChange={this.handleEndDateChange}
            dateFormat={'YYYY-MM-DD'}
            dayLabels={catalanDayLabels}
            monthLabels={catalanMonthLabels}
            weekStartsOnMonday
          />
        </FormGroup>
        &nbsp;
        <Button onClick={this.searchButton}>Cercar</Button>
      </form>
      </div>
    )
  }
}

FormBrandDateByRange.propTypes = {
  onSelectBrand: PropTypes.func.isRequired,
  startDate: PropTypes.string,
  endDate: PropTypes.string,
  onSelectStartDate: PropTypes.func.isRequired,
  onSelectEndDate: PropTypes.func.isRequired,
  onSearchButton: PropTypes.func.isRequired
}

export default FormBrandDateByRange
