import React from 'react'
import PropTypes from 'prop-types'
import { Label, Button, Glyphicon } from 'react-bootstrap'
import axios from 'axios'
import { Form, FormGroup, FormControl, Checkbox, ControlLabel} from 'react-bootstrap'
import { Modal, ModalBody, ModalHeader, ModalTitle, ModalFooter } from 'react-bootstrap'

import config from '../../../../_config'

const urlBase = `http://${window.location.hostname}:${window.location.port}`

const isInArray = (array, value) => array.indexOf(value) !== -1

config.dictionary_terms_categories.unshift('genèric')

class ViralTweetRow extends React.PureComponent {
  constructor(props) {
    super(props)
    this.state = {
      tourist: this.props.tourist,
      tweet_id_str: this.props.tweet_id_str,
      category: this.props.category,
      canonical_name: this.props.canonical_name,
      canonicalNamesFound: [],
      tweet_lang: this.props.tweet_lang,
      showModal: false,
    }
    // Handlers to capture events (as forms and buttons) should be declared and bind to the context here
    this.handleChangeTourist = this.handleChangeTourist.bind(this)
    this.handleUpdate = this.handleUpdate.bind(this)
    this.handleClose = this.handleClose.bind(this)
    this.handleSave = this.handleSave.bind(this)
    this.handleChangeCategory = this.handleChangeCategory.bind(this)
    this.handleChangeCanonicalName = this.handleChangeCanonicalName.bind(this)
    this.handleChangeTweetLang = this.handleChangeTweetLang.bind(this)
  }

  // Load canonicals into the corresponding state variable.
  // It will be used to identify canonical names present in the viral tweets
  // ------------------------------------------------------------------------
  componentDidMount() {
    this.findCanonicalsByCategory(this.props.category, this.props.brand)
  }

  handleChangeTourist(brand, tweet_id_str, tourist, category, canonical_name) {
    // let year = '20' + /^(\d\d)-\d\d/.exec(this.props.month)[1]
    let updated_tourist_flag = (tourist) ? false : true
    let request =
      '/rest_tweets_retweets/entries/month/' + this.props.month +
      '/brand/' + brand +
      '/id/' + tweet_id_str +
      '/tourist/' + updated_tourist_flag +
      '/category/' + category +
      '/canonical_name/' + canonical_name + '/'

    axios.get(`${urlBase}${request}`)
      .then((response) => {
          this.setState({ tourist: updated_tourist_flag })
          console.log(response.status)
      })
      .catch((error) => {
        alert(error)
      })
}

  handleUpdate(id, category, canonical_name, tweet_lang) {
    this.setState({
      showModal: true,
      category: category,
      canonical_name: canonical_name,
      tweet_lang: tweet_lang
    });
  }

  handleSave() {

    this.setState({
      showModal: false,
    })

    let request = '/rest_tweets_retweets/update/';
    let tweet_id_str = this.state.tweet_id_str
    let category = document.getElementById('formCategoryModal').value
    let canonical_name = document.getElementById('formCanonicalModal').value
    let tweet_lang = document.getElementById('formLangModal').value
    axios.put(`${urlBase}${request}`, {
      month: this.props.month,
      brand: this.props.brand,
      tweet_id_str: tweet_id_str,
      category: category,
      canonical_name: canonical_name,
      tweet_lang: tweet_lang
    })
    .then((response) => {
      this.props.onUpdateViralTweetsTable(tweet_id_str, category, canonical_name, tweet_lang);
      this.setState({
        showModal: false,
        tweet_lang: tweet_lang,
        category: category,
        canonical_name: canonical_name
      })
      console.log(response.status)
    })
    .catch((error) => {
      alert(error)
    })
  }

  handleClose() {
    this.setState({ showModal: false });
  }

  handleChangeCategory(e) {
    this.findCanonicalsByCategory(e.target.value, this.props.brand)

    this.setState({
      category: e.target.value
    });
  }

  handleChangeCanonicalName(e) {
    this.setState({
      canonical_name: e.target.value
    });
  }

  handleChangeTweetLang(e) {
    this.setState({
      tweet_lang: e.target.value
    });
  }

    // Other functions

  createOptionsList(mylist) {
    let options = []
    mylist.forEach((name, index) => {
      options.push(<option value={name} key={(index + 1).toString()} style={{fontStyle: 'italic'}}>-- {name} --</option>)
    })
    return options
  }

  // Extrae los nombre canónicos y sus categorías del diccionario de términos
  // -------------------------------------------------------------------------------------------
  findCanonicalsByCategory(category, brand) {
    let foundCanonicals = []

    this.props.dictionaryTerms.forEach((dictEntry) => {
      let mycanonical = `${dictEntry._canonical_name}`
      if (`${dictEntry.brand}` === brand && `${dictEntry.category}` === category) {  // chequeamos sólo alias de la marca seleccionada
        if ( !isInArray(foundCanonicals, mycanonical) ) {
          foundCanonicals.push(mycanonical)
        }
      }
    })
    foundCanonicals.sort()
    this.setState({
      canonicalNamesFound: foundCanonicals.concat(['genèric'])
    })
  }

  addChildren() {
    let children = []

    if (this.state.category) {
      // children.push(<td style={{color: 'grey'}}>{this.props.dict_category}</td>)
      children.push(<td>{this.state.category}</td>)
    } else if (this.props.dict_category){
      children.push(<td>{this.props.dict_category}</td>)
    } else {
      children.push(<td>genèric</td>)
    }
    if (this.state.canonical_name) {
      children.push(<td>{this.state.canonical_name}</td>)
    } else if (this.props.dict_canonical_name) {
      children.push(<td>{this.props.dict_canonical_name}</td>)
    } else {
      children.push(<td>genèric</td>)
    }
    return children
  }


  render() {
    return (
      <tr>
        <Modal show={this.state.showModal} onHide={this.handleClose}>
          <ModalHeader closeButton>
            <ModalTitle>Modifica Tweet</ModalTitle>
          </ModalHeader>
          <ModalBody>
            <Form>
              <FormGroup controlId="formCategoryModal">
                <ControlLabel>&nbsp;Categoria&nbsp;</ControlLabel>
                <FormControl componentClass="select" placeholder="Category" onChange={this.handleChangeCategory} value={this.state.category}>
                    {this.createOptionsList(config.dictionary_terms_categories)}
                </FormControl>
              </FormGroup>
              <FormGroup controlId="formCanonicalModal">
                <ControlLabel>&nbsp;Canonical&nbsp;</ControlLabel>
                <FormControl componentClass="select" placeholder="Canonical" onChange={this.handleChangeCanonicalName}
                      value={this.state.canonical_name}
                >
                  {this.createOptionsList(this.state.canonicalNamesFound)}
                </FormControl>
              </FormGroup>
              <FormGroup controlId="formLangModal">
                <ControlLabel>&nbsp;Idioma&nbsp;</ControlLabel>
                <FormControl componentClass="select" placeholder="select" onChange={this.handleChangeTweetLang} value={this.state.tweet_lang}>
                  {this.createOptionsList(['altres', 'es', 'ca', 'de', 'en', 'fr', 'it'])}
                </FormControl>
              </FormGroup>
            </Form>
          </ModalBody>
          <ModalFooter>
            <Button onClick={this.handleClose}>Close</Button>
            <Button onClick={() => this.handleSave()}>Save Changes</Button>
          </ModalFooter>
        </Modal>
        <td style={{whiteSpace: 'nowrap'}}>{this.props.tweet_created_at}</td>
        <td style={{wordBreak: 'break-all'}}>
          <a target="_blank" href={`https://www.twitter.com/${this.props.user_screen_name}/status/${this.props.tweet_id_str}`}>
            {this.props.tweet_text}
          </a>
        </td>
        <td style={{textAlign: 'center'}}>{this.state.tweet_lang}</td>
        <td><a target="_blank" href={`https://www.twitter.com/${this.props.user_screen_name}`}>{this.props.user_screen_name}</a></td>
        {this.addChildren()}
        <td style={{textAlign: 'center'}}><Label bsStyle="success">{this.props.count}</Label></td>
        <td style={{textAlign: 'center'}}>
          <form>
            <FormGroup controlId="isTouristChecbox">
              <Checkbox name={this.props.tweet_id_str} checked={this.state.tourist} onChange={() =>
                this.handleChangeTourist(this.props.brand,
                  this.props.tweet_id_str,
                  this.state.tourist,
                  this.state.category,
                  this.state.canonical_name)}
              />
            </FormGroup>
          </form>
        </td>
        <td style={{textAlign: 'center'}}>
          <Button bsSize="medium"
          onClick={() => this.handleUpdate(this.state.tweet_id_str, this.state.category, this.state.canonical_name, this.state.tweet_lang)}
          >
            <Glyphicon glyph="pencil" active/>
          </Button>
        </td>
      </tr>
    )
  }
}

ViralTweetRow.propTypes = {
  brand: PropTypes.string,
  month: PropTypes.string,
  tweet_id_str: PropTypes.string,
  tweet_created_at: PropTypes.string,
  tweet_text: PropTypes.string,
  tweet_lang: PropTypes.string,
  user_id_str: PropTypes.string,
  user_screen_name: PropTypes.string,
  category: PropTypes.string,
  canonical_name: PropTypes.string,
  dict_category: PropTypes.string,
  dict_canonical_name: PropTypes.string,
  tourist: PropTypes.bool,
  count: PropTypes.number,
  dictionaryTerms: PropTypes.array,
  onUpdateViralTweetsTable: PropTypes.func
}

export default ViralTweetRow
