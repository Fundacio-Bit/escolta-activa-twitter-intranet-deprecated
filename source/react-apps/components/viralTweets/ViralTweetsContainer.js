import React from 'react'
import { Grid, Row, Col } from 'react-bootstrap'
import axios from 'axios'

import Title from '../_Commons/Title'
import ErrorMessage from '../_Commons/ErrorMessage'
import FormBrandMonth from '../_Commons/FormBrandMonth'
import ViralTweetsTable from './ViralTweetsTable'


const urlBase = `http://${window.location.hostname}:${window.location.port}`

const isInArray = (array, value) => array.indexOf(value) !== -1

var today = new Date()
var current_month = today.getMonth() + 1
if (current_month < 10) {
  current_month = '0' + current_month
}
var month_year = today.getFullYear().toString().substring(2, 4) + '-' + current_month

class ViralTweetsContainer extends React.Component {
  constructor() {
    super()
    this.state = {
      dictionaryTerms: [],
      discardedInfluencers: [],
      blacklists: {},
      error: { exists: false, message: '' },
      brand: '-1',
      month: month_year,
      viralTweets: [],  // tweets aggregated by tweet count (all the aggregated)
      viralTweetsFiltered: [],  // aggregated tweets and filtered by term (word)
      canonicalNamesFound: [],
      dictionaryCategoriesFound: [],
      showLoadingIcon: false,
      showTweetsTable: false,
      selectedCanonical: '0',  // canonical selected from the selector (if it appears)
      selectedCategory: '0'  // category selected from the selector (if it appears)
    }
    // Handlers to capture events (as forms and buttons) should be declared and bind to the context here
    this.handleSelectBrand = this.handleSelectBrand.bind(this)
    this.handleSelectMonth = this.handleSelectMonth.bind(this)
    this.handleSortByColumn = this.handleSortByColumn.bind(this)
    this.handleSearchButton = this.handleSearchButton.bind(this)
    this.handleSelectCanonical = this.handleSelectCanonical.bind(this)
    this.handleSelectCategory = this.handleSelectCategory.bind(this)
    this.updateViralTweetsTable = this.updateViralTweetsTable.bind(this)
  }

  // Load the terms dictionary into the corresponding state variable.
  // It will be used to identify canonical names present in the viral tweets
  // ------------------------------------------------------------------------
  componentDidMount() {
    this.initializeTermsDictionary(urlBase)
    this.initializeDiscardedInfluencersList(urlBase)
    this.initializeBlacklistsObject(urlBase)
  }

  // Load the terms dictionary
  // --------------------------
  initializeTermsDictionary(base_url) {
    let request = '/rest_dictionary_terms/entries/category/--all--/brand/--all--'

    axios.get(`${base_url}${request}`)
      .then((response) => {        
        // Remove spaces between commas in the alias fields
        // -----------------------------------------------
        let mydict = response.data.results
        mydict.forEach((x) => {
          x.alias = x.alias.replace(/, /g, ',')
        })

        this.setState({
          dictionaryTerms: mydict
        })
      })
      .catch((error) => {
        alert(error)
      })
  }

  // Load the terms dictionary
  // --------------------------
  initializeDiscardedInfluencersList(base_url){
    let request = '/rest_dictionary_influencers/entries/category/--all--'

    axios.get(`${base_url}${request}`)
      .then((response) => {
        let myinfluencers = response.data.items.sort()

        myinfluencers = myinfluencers.filter((x) => x.category.trim() === 'descartats')
        myinfluencers = myinfluencers.map((influencer) => {
            return influencer.normalized_id
        })
        this.setState({
          discardedInfluencers: myinfluencers
        })
      })
      .catch((error) => {
        alert(error)
      })
  }

  // Load the terms dictionary
  // --------------------------
  initializeBlacklistsObject(base_url){
    let request = '/rest_blacklists/entries/brand/--all--'

    axios.get(`${base_url}${request}`)
      .then((response) => {
        let myblacklists = response.data.result
        console.log(myblacklists)
        this.setState({
          blacklists: myblacklists
        })
      })
      .catch((error) => {
        alert(error)
      })
  }

  // Handle selectors and buttons
  handleSelectBrand(selectedBrand) {
    this.setState({
      brand: selectedBrand
    })
  }

  handleSelectCanonical(selectedCanonical) {
    let mytweets = []

    if (selectedCanonical === '0') { // -- TOTS --
      mytweets = this.state.viralTweets
    } else if (selectedCanonical === '-1') { // -- AMB CANÔNIC --
      // Get the tweets that contain an alias of the selected Canonical
      // ----------------------------------------------------------
      this.state.viralTweets.forEach((tweet) => {
        if (tweet.canonical_name !== 'genèric'){
          mytweets.push(tweet)
        }
      })
    } else if (selectedCanonical === '-2') { // -- GENÈRIC --
      this.state.viralTweets.forEach((tweet) => {
        if (tweet.canonical_name === 'genèric') {
          mytweets.push(tweet)
        }
      })
    } else {
      // Get the tweets that contain at leat one alias of the selected canonical
      // -----------------------------------------------------------------------
      this.state.viralTweets.forEach((tweet) => {
        if (tweet.canonical_name === selectedCanonical){
          mytweets.push(tweet)
        }
      })
    }

    this.setState({
      selectedCanonical: selectedCanonical,
      selectedCategory: '0',  // remove categories filter
      viralTweetsFiltered: mytweets,
    })
  }

  handleSelectCategory(selectedCategory) {
    let mytweets = []

    if (selectedCategory === '0') {
      // -- TOTS --
      mytweets = this.state.viralTweets

  } else if (selectedCategory === '-1') {
    // -- AMB CATEGORIA --

      // Get viral tweets with category different from 'genèric'
      this.state.viralTweets.forEach((tweet) => {
        if (tweet.category !== 'genèric') {
          mytweets.push(tweet)
        }
      })
    } else if (selectedCategory === '-2') {
        // -- GENERICS --

        // Get the tweets that contain an alias of the selected brand
        // ----------------------------------------------------------
        this.state.viralTweets.forEach((tweet) => {
          if (tweet.category === 'genèric') {
            mytweets.push(tweet)
          }
        })
    } else {
      // Extract those that contain an alias from the selected category
      // ---------------------------------------------------------------
      this.state.viralTweets.forEach((tweet) => {
        if (tweet.category === selectedCategory) {
          mytweets.push(tweet)
        }
      })
    }

    this.setState({
      selectedCanonical: '0',  // quitamos filtro de canónicos
      selectedCategory: selectedCategory,
      viralTweetsFiltered: mytweets
    })
  }

  handleSelectMonth(value) {
    let month = ''
    if (value) {
      month = /^(\d\d)\/(\d\d)/.exec(value)
    }
    this.setState({
      month: month[1] + '-' + month[2]
    })
  }

  handleSortByColumn(order, field) {
    let sorted_tweets = [].concat(this.state.viralTweetsFiltered)

    if (order === 'asc') {
      sorted_tweets.sort(this.sortFunctionAsc(field))
    } else {
      sorted_tweets.sort(this.sortFunctionDesc(field))
    }

    this.setState({
      viralTweetsFiltered: sorted_tweets
    })
  }

  handleSearchButton() {
    // -------------------------------------
    // Validate form when clicking "search"
    // -------------------------------------
    let validation = this.validateForm()

    if (validation !== 'ok') {
      this.setState({
        error: { exists: true, message: validation },
        showLoadingIcon: false,
        showTweetsTable: false
      })
      setTimeout(() => { this.setState({ error: { exists: false, message: '' } }) }, 2250)
      return
    }

    // ------------------
    // VALIDATION = 'OK'
    // ------------------

    // Show loading icon (and delete current table if it exists)
    // --------------------------------------------------------------------------
    this.setState({
      error: { exists: false, message: '' },
      showLoadingIcon: true,
      showTweetsTable: false,
      selectedCanonical: '0',  // remove canonical_names filter
      selectedCategory: '0'  // remove categroies filter
    })

    let request = `/rest_tweets_retweets/viral_tweets/month/${this.state.month}/brand/${this.state.brand}`

    axios.get(`${urlBase}${request}`)
      .then((response) => {

        // Check for errors
        // ------------------------
        if (response.data.hasOwnProperty('error')) {
          this.setState({
            error: { exists: true, message: response.data.error },
            showLoadingIcon: false,
            showTweetsTable: false
          })
          setTimeout(() => { this.setState({ error: { exists: false, message: '' } }) }, 2250)
          return
        }
        // Aggregate and order tweets by count
        // -------------------------------------
        let tweets = response.data.results

        // Remove viral tweets from excluded influencers
        // -----------------------------------------------
        tweets = tweets.filter((tweet) => !isInArray(this.state.discardedInfluencers, tweet.user_screen_name.toLowerCase()))

        // Remove viral tweets with blacklisted terms
        // --------------------------------------------
        this.state.blacklists[this.state.brand].forEach( (term) => {
          tweets = tweets.filter((tweet) => !isInArray(tweet.words.split(','), term.toLowerCase()))
        })

        // Add 'key' field used by React and infer possible 'category' and 'canonical_name' for each viral tweet
        // -----------------------------------------------------------------------------------------------------
        tweets.forEach((item) => {
          item.key = `${item.tweet_id_str}`  // concatenamos id_str original

          if (!item.category || !item.canonical_name) {
            let foundAlias = false
            this.state.dictionaryTerms.forEach((dictEntry) => {
              if (dictEntry.brand === this.state.brand) {  // chequeamos sólo alias de la marca seleccionada
                dictEntry.alias.split(',').forEach((alias) => {
                  if (isInArray(item.words.split(','), alias)) {
                    item.category = `${dictEntry.category}`
                    item.canonical_name = `${dictEntry._canonical_name}`
                    foundAlias = true
                  }
                })
              }
            })
            if (!foundAlias) {
              item.category = 'genèric'
              item.canonical_name = 'genèric'
            }
          }
        })

        // Filter by categories and canonical_names
        // ----------------------------------------
        this.findCanonicalsAndCategories(tweets)

        this.setState({
          viralTweets: tweets,
          viralTweetsFiltered: tweets,
          showLoadingIcon: false,
          showTweetsTable: true
        })
      })
      .catch((error) => {
        alert(error)
      })
  }

  // Other functions
  validateForm() {
    if (this.state.brand === '-1') {
      return 'Seleccioni el camp \'Marca\''
    }

    if (this.state.month === '') {
      return 'Seleccioni \'Mes\''
    }

    return 'ok'
  }

  // Descending sort function by 'field'
  // ------------------------------------
  sortFunctionDesc(field) {
    const compare = (a, b) => {
      var aField = a[field]
      var bField = b[field]
      if (typeof a[field] === 'string') {
        aField = a[field].toLowerCase()
      }
      if (typeof b[field] === 'string') {
        bField = b[field].toLowerCase()
      }
      if (aField < bField) { return 1 }
      if (aField > bField) { return -1 }
      return 0
    }
    return compare
  }

  // Ascending sort function by 'field'
  // -----------------------------------
  sortFunctionAsc(field) {
    const compare = (a, b) => {
      var aField = a[field]
      var bField = b[field]
      if (typeof a[field] === 'string') {
        aField = a[field].toLowerCase()
      }
      if (typeof b[field] === 'string') {
        bField = b[field].toLowerCase()
      }

      if (aField < bField) { return -1 }
      if (aField > bField) { return 1 }
      return 0
    }
    return compare
  }

  //Extract canonical and categories for the viral tweets list
  // ---------------------------------------------------------
  findCanonicalsAndCategories(viralTweets) {
    let headCanonicals = ['-- TOTS --', '-- AMB CANÒNIC --', '-- GENÈRICS --']
    let headCategories = ['-- TOTS --', '-- AMB CATEGORIA --', '-- GENÈRICS --']
    let foundCanonicals = []
    let foundCategories = []
    viralTweets.forEach((tweet) => {
        if (!isInArray(foundCategories, tweet.category)) {
          if (tweet.category !== 'genèric') {
            foundCategories.push(tweet.category)
          }
        }
        if (tweet.canonical_name !== 'genèric') {
          let canonical_entry = tweet.canonical_name + ' (' + tweet.category + ')'
          if (!isInArray(foundCanonicals, canonical_entry)) {
            foundCanonicals.push(canonical_entry)
          }
        }
      })

    foundCanonicals.sort()
    foundCategories.sort()
    this.setState({
      canonicalNamesFound: headCanonicals.concat(foundCanonicals),
      dictionaryCategoriesFound: headCategories.concat(foundCategories)
    })
  }


  showErrorMessage() {
    if (this.state.error.exists) {
      return (
        <div>
          <ErrorMessage message={this.state.error.message} />
        </div>
      )
    }
  }

  showLoadingIcon() {
    if (this.state.showLoadingIcon) {
      return (
        <p className={'text-center'}>
          <img src={`${urlBase}/img/rendering.gif`} />&nbsp;Processant tweets. Per favor, <b>esperi</b>...
        </p>
      )
    } else {
      return ''
    }
  }

  showTweetsTable() {
    if (this.state.showTweetsTable) {
      return (
        <ViralTweetsTable
          month={this.state.month}
          brand={this.state.brand}
          tweets={this.state.viralTweetsFiltered}
          dictionaryTerms={this.state.dictionaryTerms}
          onSortByColumn={this.handleSortByColumn}
          canonicalsList={this.state.canonicalNamesFound}
          categoriesList={this.state.dictionaryCategoriesFound}
          onSelectCanonical={this.handleSelectCanonical}
          onSelectCategory={this.handleSelectCategory}
          selectedCanonical={this.state.selectedCanonical}
          selectedCategory={this.state.selectedCategory}
          onUpdateViralTweetsTable={this.updateViralTweetsTable}
        />
      )
    } else {
      return ''
    }
  }


  // Update the viral tweets table
  // This function will pass to the child rows to facilitate reload on edits
  // ------------------------------------------------------------------------
  updateViralTweetsTable(tweet_id, categ, canonical, lang) {
    // this.handleSearchButton()
    let updatedViralTweets = this.state.viralTweets.map((tweet) => {
      if (tweet.key === tweet_id) {
        tweet.category = categ
        tweet.canonical_name = canonical
        tweet.lang = lang
      }
      return tweet
    })

    this.findCanonicalsAndCategories(updatedViralTweets)
    this.setState({
      viralTweets: updatedViralTweets,
      // viralTweetsFiltered: updatedViralTweetsFiltered
    })
  }

  render() {
    return (
      <Grid fluid>
        <Row>
          <Col md={12}>
            <Title name={'Tweets virals'} />
          </Col>
        </Row>
        <Row>
          <Col md={12}>
            <FormBrandMonth
              onSelectBrand={this.handleSelectBrand}
              month={this.state.month}
              onSelectMonth={this.handleSelectMonth}
              onSearchButton={this.handleSearchButton}
            />
          </Col>
        </Row>
        <Row>
          <Col md={12}>
            {this.showErrorMessage()}
            {this.showLoadingIcon()}
            {this.showTweetsTable()}
          </Col>
        </Row>
      </Grid>
    )
  }
}

export default ViralTweetsContainer
