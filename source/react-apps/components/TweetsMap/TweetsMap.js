import React, { Component } from 'react'
import PropTypes from 'prop-types'

import {
  ComposableMap,
  ZoomableGroup,
  Geographies,
  Geography,
  Markers,
  Marker,
} from 'react-simple-maps'

const wrapperStyles = {
  width: '100%',
  maxWidth: 980,
  margin: '0 auto',
}

// Array of countries that will be displayed on the map (3-letters ISO CODE)
const include = [
  'AZE', 'ALB', 'ARM', 'BIH', 'BGD', 'CYP', 'DNK', 'IRL', 'EST', 'AUT', 'CZE', 'FIN', 'FRA', 'GEO',
  'DEU', 'GRC', 'HRV', 'HUN', 'ISL', 'ITA', 'LVA', 'BLR', 'LTU', 'SVK', 'LIE', 'MKD',  'BEL', 'AND',
  'LUX', 'MCO', 'MNE', 'NLD', 'NOR', 'POL', 'PRT', 'ROU', 'MDA', 'SVN', 'ESP', 'SWE', 'CHE', 'TUR',
  'GBR', 'UKR', 'SMR', 'SRB', 'VAT', 'RUS'
]

class TweetsMap extends Component {
  constructor() {
    super()
  }

  render() {
     return (
      <div style={wrapperStyles}>
        <ComposableMap
          projectionConfig={{ scale: 650 }}
          // width={750}
          // height={600}
          style={{
            width: '100%',
            height: 'auto',
          }}
        >
          <ZoomableGroup center={[15.891846, 54.592830 ]}>
            <Geographies geography='/static/world-50m.json'>
              {(geographies, projection) =>
                geographies.map((geography, i) =>
                  include.indexOf(geography.id) !== -1 && (
                    <Geography
                      key={i}
                      geography={geography}
                      projection={projection}
                      style={{
                        default: {
                          fill: '#ECEFF1',
                          stroke: '#607D8B',
                          strokeWidth: 0.75,
                          outline: 'none',
                        },
                        hover: {
                          fill: '#CFD8DC',
                          stroke: '#607D8B',
                          strokeWidth: 0.75,
                          outline: 'none',
                        },
                        pressed: {
                          fill: '#FF5722',
                          stroke: '#607D8B',
                          strokeWidth: 0.75,
                          outline: 'none',
                        },
                      }}
                    />
                  )
                )
              }
            </Geographies>
            <Markers>
              {this.props.coordinates.length > 0 && this.props.coordinates.map((marker, i) => (
                <Marker
                  key={i}
                  marker={marker}
                  style={{
                    default: { fill: '#FF5722', opacity: 0.6 },
                    hover: { fill: '#FFFFFF' },
                    pressed: { fill: '#FF5722' },
                  }}
                >
                  <circle
                    cx={0}
                    cy={0}
                    r={2}
                    style={{
                      stroke: '#FF5722',
                      strokeWidth: 3,
                      opacity: 0.9,
                    }}
                  />
                </Marker>
              ))}
            </Markers>
          </ZoomableGroup>
        </ComposableMap>
      </div>
    )
  }
}

TweetsMap.propTypes = {
  coordinates: PropTypes.array,
}

export default TweetsMap
