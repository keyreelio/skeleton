webpack= require('webpack');
module.exports =
[
    {
        entry:"./src/front/content.coffee",
        devtool: "source-map",
        module: {
            loaders: [
                {
                    test: /\.(coffee\.md|litcoffee)$/,
                    loader: "coffee-loader?literate"
                },

                {
                    test: /\.coffee$/,
                    loader: "coffee-loader"
                },

                {
                    test: /\.coffee$/, // include .coffee files
                    exclude: /node_modules/, // exclude any and all files in the node_modules folder
                    loader: "coffeelint-loader"
                },
            ]
        },
        plugins: [
        new webpack.optimize.UglifyJsPlugin({
            minimize: true,
            compress: {
                warnings: false
            }
        })
        ],
        output:
        {
            filename: "content.min.js"
        }
    },

    {
    entry:"./src/back/background.coffee",
        devtool: "source-map",
        module: {
            loaders: [
                {
                    test: /\.(coffee\.md|litcoffee)$/,
                    loader: "coffee-loader?literate"
                },

                {
                    test: /\.coffee$/,
                    loader: "coffee-loader"
                },

                {
                    test: /\.coffee$/, // include .coffee files
                    exclude: /node_modules/, // exclude any and all files in the node_modules folder
                    loader: "coffeelint-loader"
                },
            ]
        },
        plugins: [
        new webpack.optimize.UglifyJsPlugin({
            minimize: true,
            compress: {
                warnings: false
            }
        })
        ],
        output:
        {
            filename: "background.min.js"
        }

    }
]
