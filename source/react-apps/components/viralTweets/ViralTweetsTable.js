import React from 'react'
import PropTypes from 'prop-types'
import { Grid, Row, Col, FormGroup, FormControl, Table } from 'react-bootstrap'

import HeaderColumn from './HeaderColumn'
import ViralTweetRow from './ViralTweetRow'


class ViralTweetsTable extends React.Component {
  constructor(props) {
    super(props)
    this.handleCanonicalChange = this.handleCanonicalChange.bind(this)  // vincula al contexto de este componente
    this.handleCategoryChange = this.handleCategoryChange.bind(this)
  }

  createOptionsList(mylist) {
    let options = []

    var count = 0
    mylist.forEach((name, index) => {
      if (name.includes('--')) {
        options.push(<option value={count} key={count.toString()} style={{fontStyle: 'italic'}}>-- {name} --</option>)
        --count
      } else {
        options.push(<option value={name.replace(/\s\(.*\)/, '')} key={(index + 1).toString()} style={{fontStyle: 'italic'}}>-- {name} --</option>)
      }
    })
    return options
  }

  handleCanonicalChange(e) {
    this.props.onSelectCanonical(e.target.value)
  }

  handleCategoryChange(e) {
    this.props.onSelectCategory(e.target.value)
  }

  render() {

    const rows = []

    // Añadimos cabecera
    rows.push(
      <tr key={'header'}>
        <td style={{whiteSpace: 'nowrap'}}>
          <HeaderColumn
            onSortByColumn={this.props.onSortByColumn}
            fieldName={'tweet_created_at'}
            columnName={'data'}
          />
        </td>
        <td style={{whiteSpace: 'nowrap'}}><strong>text original</strong></td>
        <td style={{whiteSpace: 'nowrap'}}>
          <HeaderColumn
            onSortByColumn={this.props.onSortByColumn}
            fieldName={'tweet_lang'}
            columnName={'idioma'}
          />
        </td>
        <td style={{whiteSpace: 'nowrap'}}>
          <HeaderColumn
            onSortByColumn={this.props.onSortByColumn}
            fieldName={'user_screen_name'}
            columnName={'autor'}
          />
        </td>
        <td style={{whiteSpace: 'nowrap'}}>
          <HeaderColumn
            onSortByColumn={this.props.onSortByColumn}
            fieldName={'category'}
            columnName={'cat'}
          />
        </td>
        <td style={{whiteSpace: 'nowrap'}}>
          <HeaderColumn
            onSortByColumn={this.props.onSortByColumn}
            fieldName={'canonical_name'}
            columnName={'canònic'}
          />
        </td>
        <td style={{whiteSpace: 'nowrap'}}>
          <HeaderColumn
            onSortByColumn={this.props.onSortByColumn}
            fieldName={'count'}
            columnName={'retweets'}
          />
        </td>
        <td style={{whiteSpace: 'nowrap'}}>
          <HeaderColumn
            onSortByColumn={this.props.onSortByColumn}
            fieldName={'touristic'}
            columnName={'turístic'}
          />
        </td>
        <td>&nbsp;</td>
      </tr>
    )

    this.props.tweets.forEach((tweet) => {
      rows.push(
        <ViralTweetRow
          brand={this.props.brand}
          month={this.props.month}
          tweet_created_at={tweet.tweet_created_at}
          tweet_text={tweet.tweet_text}
          tweet_lang={tweet.tweet_lang}
          tweet_id_str={tweet.tweet_id_str}
          user_screen_name={tweet.user_screen_name}
          user_id_str={tweet.user_id_str}
          category={tweet.category}
          canonical_name={tweet.canonical_name}
          count={tweet.count}
          tourist={tweet.touristic}
          key={tweet.key}
          dictionaryTerms={this.props.dictionaryTerms}
          onUpdateViralTweetsTable={this.props.onUpdateViralTweetsTable}
        />
      )
    })

    return (
      <Grid fluid>
        <Row>
          <Col md={12}>
            &nbsp;
          </Col>
        </Row>
        <Row>
          <Col md={2}>
            S'han trobat <strong>{this.props.tweets.length}</strong> Tweets Virals per <strong>{this.props.brand.toUpperCase()}</strong>.
          </Col>
          <Col md={4}>
            Trobats <strong>{this.props.canonicalsList.length - 3}</strong> Noms Can&ograve;nics.
            <form>
              <FormGroup controlId="formCanonical">
                <FormControl value={this.props.selectedCanonical} componentClass="select" placeholder="select" onChange={this.handleCanonicalChange}>
                  {this.createOptionsList(this.props.canonicalsList)}
                </FormControl>
              </FormGroup>
            </form>
          </Col>
          <Col md={4}>
            Trobades <strong>{this.props.categoriesList.length - 3}</strong> Categories.
            <form>
              <FormGroup controlId="formCategory">
                <FormControl value={this.props.selectedCategory} componentClass="select" placeholder="select" onChange={this.handleCategoryChange}>
                  {this.createOptionsList(this.props.categoriesList)}
                </FormControl>
              </FormGroup>
            </form>
          </Col>
          <Col md={2}>
          Mínim de retweets <b>10</b>.
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

ViralTweetsTable.propTypes = {
  brand: PropTypes.string,
  month: PropTypes.string,
  tweets: PropTypes.array,
  dictionaryTerms: PropTypes.array,
  canonicalsList: PropTypes.array,
  categoriesList: PropTypes.array,
  onSortByColumn: PropTypes.func,
  onSelectCanonical: PropTypes.func,
  onSelectCategory: PropTypes.func,
  // onSelectNumViralTweets: PropTypes.func,
  selectedCanonical: PropTypes.string,
  selectedCategory: PropTypes.string,
  // minRetweets: PropTypes.number,
  onUpdateViralTweetsTable: PropTypes.func
}

export default ViralTweetsTable
