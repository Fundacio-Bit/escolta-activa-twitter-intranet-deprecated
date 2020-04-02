import React from 'react'
import { Grid, Row, Col, FormGroup, FormControl, ControlLabel, Button,
   Modal, ModalBody, ModalHeader, ModalTitle, ModalFooter } from 'react-bootstrap'
import axios from 'axios'

import config from '../../../../_config'
import Title from '../_Commons/Title'
import InfluencersTable from './InfluencersTable'

const urlBase = `http://${window.location.hostname}:${window.location.port}`
console.log(`urlBase = ${urlBase}`)

class DictionaryInfluencersContainer extends React.Component {
  constructor() {
    super()
    this.state = {
      show: false,
      influencer: '',
      subcategory: '',
      selectedCategory: '-1',
      influencersAll: [],
      influencersFiltered: [],
      showLoadingIcon: false,
      showInfluencersTable: false,
    }
    this.handleSortByColumn = this.handleSortByColumn.bind(this)
    this.updateInfluencersTable = this.updateInfluencersTable.bind(this)
    this.handleCategory = this.handleCategory.bind(this)
    this.handleSearchButton = this.handleSearchButton.bind(this)
    this.handleShow = this.handleShow.bind(this)
    this.handleClose = this.handleClose.bind(this)
    this.handleNewInfluencer = this.handleNewInfluencer.bind(this)
    this.handleSubcategory = this.handleSubcategory.bind(this)
    this.handleCreateInfluencer = this.handleCreateInfluencer.bind(this)
  }

  // Cargamos el diccionario de influencers
  // ---------------------------------------
  componentDidMount() {
    this.initializeInfluencersList()
  }

  updateInfluencersTable() {
    this.initializeInfluencersList()
  }


  initializeInfluencersList(){
    let request = '/rest_dictionary_influencers/entries/category/--all--'

    axios.get(`${urlBase}${request}`)
      .then((response) => {
        console.log(`Cargado diccionario con ${response.data.items.length} influencers.`)
        let myinfluencers = response.data.items.sort()

        if (this.state.selectedCategory !== '-1') {
          myinfluencers = myinfluencers.filter((x) => x.category.trim() === this.state.selectedCategory)
        }

        this.setState({
          influencersAll: response.data.items.sort(),
          influencersFiltered: myinfluencers
        })
      })
      .catch((error) => {
        alert(error)
      })
  }

  handleCategory(e) {
    this.setState({
      selectedCategory: e.target.value
    })
  }

  handleNewInfluencer(e) {
    this.setState({
      influencer: e.target.value
    })
  }

  handleSubcategory(e) {
    this.setState({
      subcategory: e.target.value
    })

  }

  handleCreateInfluencer() {
    let request = '/rest_dictionary_influencers/entries/';
    let influencer = this.state.influencer
    let subcategory = this.state.subcategory
    axios.post(`${urlBase}${request}`, {
        influencer: influencer,
        subcategory: subcategory
    })
    .then((response) => {
      this.initializeInfluencersList()
      this.setState({
        show: false,
        influencer: '',
        subcategory: ''
      });
      console.log(response.status)
    })
  }

  createOptionsList(categories) {
    let options = []
    options.push(<option value={'-1'} key={'-1'}>-- Totes --</option>)
    categories.forEach((cat) => {
      options.push(<option value={cat} key={cat}>{cat}</option>)
    })
    return options
  }

  handleSearchButton() {
    this.setState({
      showLoadingIcon: true,
      showInfluencersTable: false
    })

    // Refresh influencers table
    this.initializeInfluencersList();

    // Filter influencers table by category and shows table
    setTimeout(() => {
      let myinfluencers = this.state.influencersAll

      if (this.state.selectedCategory !== '-1') {
        myinfluencers = myinfluencers.filter((x) => x.category.trim() === this.state.selectedCategory)
      }

      this.setState({
        influencersFiltered: myinfluencers,
        showLoadingIcon: false,
        showInfluencersTable: true
      })

    }, 700)

  }

  handleShow() {
      this.setState({ show: true });
  }

  handleClose() {
      this.setState({ show: false });
  }

  // Función que devuelve una función que ordena por 'field' (Descendente)
  // ----------------------------------------------------------------------
  sortFunctionDesc(field) {
    const compare = (a, b) => {
      if (a[field] < b[field]) {return 1}
      if (a[field] > b[field]) {return -1}
      return 0
    }
    return compare
  }

  // Función que devuelve una función que ordena por 'field' (Ascendente)
  // ---------------------------------------------------------------------
  sortFunctionAsc(field) {
    const compare = (a, b) => {
      if (a[field] < b[field]) {return -1}
      if (a[field] > b[field]) {return 1}
      return 0
    }
    return compare
  }

  handleSortByColumn(order, field) {
    let sorted_influencers = [].concat(this.state.influencersFiltered)

    if (order === 'asc') {
      sorted_influencers.sort(this.sortFunctionAsc(field))
    } else {
      sorted_influencers.sort(this.sortFunctionDesc(field))
    }

    this.setState({
      influencersFiltered: sorted_influencers
    })
  }

  showLoadingIcon() {
    if (this.state.showLoadingIcon) {
      return (
        <p className={'text-center'}>
        <img src={`${urlBase}/img/rendering.gif`} />&nbsp;Processant influencers...
        </p>
      )
    } else {
      return ''
    }
  }

  showInfluencersTable() {
    if (this.state.showInfluencersTable) {
      return (
        <InfluencersTable
          influencers={this.state.influencersFiltered}
          onSortByColumn={this.handleSortByColumn}
          onUpdateInfluencersTable ={this.updateInfluencersTable}
        />
      )
    } else {
      return ''
    }
  }

  render() {
    return (
      <Grid fluid>
        <Modal show={this.state.show} onHide={this.handleClose}>
          <ModalHeader closeButton>
            <ModalTitle>Crear nova entrada</ModalTitle>
          </ModalHeader>
          <ModalBody>
            <form>
              <FormGroup controlId="newInfluencer">
                <ControlLabel>&nbsp;Influencer&nbsp;</ControlLabel>
                <FormControl type="text" value={this.state.influencer} placeholder="Influencer id" onChange={this.handleNewInfluencer} />
              </FormGroup>
              <FormGroup controlId="subCategory">
                <ControlLabel>&nbsp;SubCategoria&nbsp;</ControlLabel>
                <FormControl type="text" value={this.state.subcategory} placeholder="Subcategoria" onChange={this.handleSubcategory}/>
              </FormGroup>
            </form>
          </ModalBody>
          <ModalFooter>
            <Button onClick={this.handleClose}>Close</Button>
            <Button onClick={this.handleCreateInfluencer}>Save Changes</Button>
          </ModalFooter>
        </Modal>
        <Row>
          <Col md={12}>
            <Title name={'Diccionari d\'influencers'} />
          </Col>
        </Row>
        <Row>
          <Col md={12}>
            <form className="well form-inline">
              <FormGroup controlId="formCategory">
                  <ControlLabel>&nbsp;Categoria&nbsp;</ControlLabel>
                  <FormControl componentClass="select" placeholder="select" onChange={this.handleCategory} >
                    {this.createOptionsList(config.dictionary_influencers_categories)}
                  </FormControl>
              </FormGroup>
              &nbsp;
              <Button onClick={this.handleSearchButton}>Cercar</Button>
              <Button className="pull-right" bsStyle="primary" onClick={this.handleShow}>Crear entrada</Button>
            </form>
          </Col>
        </Row>
        <Row>
          <Col md={12}>
            {this.showLoadingIcon()}
            {this.showInfluencersTable()}
          </Col>
        </Row>
      </Grid>
    )
  }
}

export default DictionaryInfluencersContainer
