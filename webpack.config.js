const path = require('path');
const webpack = require('webpack');  // sólo para production

module.exports = {
  resolve: {
    extensions: ['.js', '.jsx']
  },
  context: __dirname,
  entry: {
    viralTweetsApp: './source/react-apps/viralTweetsApp.js',
    dictionaryInfluencersApp: './source/react-apps/dictionaryInfluencersApp.js',
    tweetsMapApp: './source/react-apps/tweetsMapApp.js'
  },
  output: {
    path: path.resolve('./public/react-build'),
    filename: '[name]_bundle.js',
    publicPath: '/react-build/'
  },

  // ------------------------ P R O D U C T I O N ----------------------------
  // Descomentar esto para production (y ejecutar: 'webpack --progress -p')
  // -------------------------------------------------------------------------
  plugins: [
    new webpack.LoaderOptionsPlugin({
      minimize: true,
      debug: false
    }),
    new webpack.DefinePlugin({
      'process.env': {
        'NODE_ENV': JSON.stringify('production')
      }
    }),
    new webpack.optimize.UglifyJsPlugin({
      beautify: false,
      mangle: {
        screw_ie8: true,
        keep_fnames: true
      },
      compress: {
        warnings: false,
        screw_ie8: true
      },
      comments: false,
      sourceMap: false
    })
  ],
  // ------------------------ P R O D U C T I O N ----------------------------

  module: {
    loaders: [
      { test: /(\.js|.jsx)$/, loader: 'babel-loader', exclude: /node_modules/ },
      { test: /\.css$/, loader: 'style-loader!css-loader' }
    ]
  }
}
