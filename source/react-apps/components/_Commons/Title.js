import React from 'react'


class Title extends React.Component {
  render() {
    return (
      <h3>{this.props.name}</h3>
    )
  }
}

Title.propTypes = {
  name: React.PropTypes.string
}

export default Title
