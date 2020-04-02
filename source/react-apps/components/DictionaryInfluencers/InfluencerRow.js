import React from 'react'
import PropTypes from 'prop-types'
import { Label, FormGroup, FormControl, ControlLabel, Button, Glyphicon } from 'react-bootstrap'
import { Modal, ModalBody, ModalHeader, ModalTitle, ModalFooter } from 'react-bootstrap'
import axios from 'axios'

import config from '../../../../_config'

const urlBase = `http://${window.location.hostname}:${window.location.port}`
console.log(`urlBase = ${urlBase}`)

class InfluencerRow extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      influencer: this.props.influencer,
      category: this.props.category,
      subcategory: this.props.subcategory,
      show: false,
    }
    this.handleRemove = this.handleRemove.bind(this)
    this.handleUpdate = this.handleUpdate.bind(this)
    this.handleClose = this.handleClose.bind(this)
    this.handleSave = this.handleSave.bind(this)
    this.handleChangeCategory = this.handleChangeCategory.bind(this)
    this.handleChangeSubcategory = this.handleChangeSubcategory.bind(this)
  }

  handleUpdate(id, subcategory) {
    this.setState({
      show: true,
      influencer: id,
      subcategory: subcategory
    });
  }

  handleSave() {
    let request = '/rest_dictionary_influencers/update/';
    let category = this.state.category
    let subcategory = this.state.subcategory
    let influencer = this.state.influencer
    axios.put(`${urlBase}${request}`, {
      influencer: influencer,
      category: category,
      subcategory: subcategory
    })
    .then((response) => {
      this.props.onUpdateInfluencersTable();
      this.setState({
        show: false
      })
      console.log(response.status)
    })
  }

  handleClose() {
    this.setState({ show: false });
  }

  handleChangeCategory(e) {
    this.setState({
      category: e.target.value
    });
  }

  handleChangeSubcategory(e) {
    this.setState({
      subcategory: e.target.value
    });
  }

  handleRemove(id){
    let request = '/rest_dictionary_influencers/delete/id/' + id;
    axios.get(`${urlBase}${request}`)
    .then((response) => {
      this.props.onUpdateInfluencersTable();
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

  render() {
    return (
      <tr>
      <Modal show={this.state.show} onHide={this.handleClose}>
          <ModalHeader closeButton>
            <ModalTitle>{this.state.influencer}</ModalTitle>
          </ModalHeader>
          <ModalBody>
            <form>
              <FormGroup controlId="formCategory">
                  <ControlLabel>&nbsp;Categoria&nbsp;</ControlLabel>
                  <FormControl componentClass="select" placeholder="select" onChange={this.handleChangeCategory} value={this.state.category}>
                    {this.createOptionsList(config.dictionary_influencers_categories)}
                  </FormControl>
              </FormGroup>
              <FormGroup controlId="subCategory">
                <ControlLabel>&nbsp;SubCategoria&nbsp;</ControlLabel>
                <FormControl type="text" value={this.state.subcategory} placeholder="Subcategoria" onChange={this.handleChangeSubcategory}/>
              </FormGroup>
            </form>
          </ModalBody>
          <ModalFooter>
            <Button onClick={this.handleClose}>Close</Button>
            <Button onClick={() => this.handleSave()}>Save Changes</Button>
          </ModalFooter>
        </Modal>
        <td><a target="_blank" href={`https://www.twitter.com/${this.props.influencer}`}><i>{this.props.influencer}</i></a></td>
        <td><Label bsStyle="success">{this.props.category.toUpperCase()}</Label></td>
        <td>{this.props.subcategory}</td>
        <td>{this.props.creation_date}</td>
        <td>{this.props.last_update}</td>
        <td>
          <Button bsSize="medium" onClick={() => this.handleUpdate(this.state.influencer, this.props.subcategory)}>
            <Glyphicon glyph="pencil" active/>
          </Button>
        </td>
        <td>
          <Button bsSize="medium" onClick={() => this.handleRemove(this.state.influencer)}>
            <Glyphicon glyph="remove" active/>
          </Button>
        </td>
      </tr>
    )
  }
}

InfluencerRow.propTypes = {
  influencer: PropTypes.string,
  category: PropTypes.string,
  subcategory: PropTypes.string,
  creation_date: PropTypes.string,
  last_update: PropTypes.string,
  onUpdateInfluencersTable: PropTypes.func
}

export default InfluencerRow
