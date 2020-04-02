import React from 'react'


class ErrorMessage extends React.Component {
  render() {
    return (
      <div className={'alert alert-danger'} role={'alert'}>
        <span className={'glyphicon glyphicon-exclamation-sign'} aria-hidden="true" />
        &nbsp;{this.props.message}
      </div>
    )
  }
}

ErrorMessage.propTypes = {
  message: React.PropTypes.string
}

export default ErrorMessage
