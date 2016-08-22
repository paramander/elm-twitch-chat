/* global process */

var AutoPrefixer = require('autoprefixer');
var CopyWebpackPlugin = require('copy-webpack-plugin');
var ExtractTextPlugin = require('extract-text-webpack-plugin');
var HtmlWebpackPlugin = require('html-webpack-plugin');
var UnminifiedWebpackPlugin = require('unminified-webpack-plugin');
var Webpack = require('webpack');
var WebpackMerge = require('webpack-merge');


var npm_target = process.env.npm_lifecycle_event;
var environment;

if (npm_target === 'start') {
    environment = 'development';
} else {
    environment = 'production';
}

var common = {
    entry: {
        app: './src/index.js'
    },

    resolve: {
        modulesDirectories: ['node_modules'],
        extensions: ['', '.js', '.elm']
    },

    module: {
        loaders: [{
            test: /\.(eot|svg|ttf|woff|woff2)(\?v=\d+\.\d+\.\d+)?/,
            loader: 'file-loader'
        }],

        noParse: /^(?!.*Stylesheets).*\.elm$/
    },

    plugins: [
        new HtmlWebpackPlugin({
            template: 'src/index.html'
        }),
        new Webpack.optimize.CommonsChunkPlugin({
            name: "init",
            minChunks: Infinity
        }),
        new Webpack.optimize.OccurenceOrderPlugin()
    ],

    postcss: [AutoPrefixer({
        browsers: ['last 2 versions']
    })],

    target: 'web'
};


if (environment === 'development') {
    console.log('running development');

    var devOnly = {
        output: {
            filename: '[name].js'
        },

        module: {
            loaders: [
                {
                    test: /src\/Stylesheets.elm$/,
                    loaders: [
                        'style-loader',
                        'css-loader',
                        'postcss-loader',
                        'elm-css-webpack-loader'
                    ]
                },
                {
                    test: /\.elm$/,
                    exclude: [
                        /elm-stuff/,
                        /node_modules/,
                        /src\/Stylesheets.elm$/
                    ],
                    loaders: [
                        'elm-hot-loader',
                        'elm-webpack-loader'
                    ]
                }
            ]
        },

        devServer: {
            inline: true,
            progress: true,
            stats: 'errors-only'
        }
    };

    module.exports = WebpackMerge(common, devOnly);
}
