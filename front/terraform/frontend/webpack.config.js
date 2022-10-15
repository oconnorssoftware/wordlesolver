const webpack = require("webpack");
const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");
const dotenv = require('dotenv');

module.exports = () => {
	const denv = dotenv.config().parsed;

	// reduce it to a nice object, the same as before
 	const envKeys = Object.keys(denv).reduce((prev, next) => {
    	prev[`process.env.${next}`] = JSON.stringify(denv[next]);
		return prev;
	}, {});

	return {
		entry: "./src/index.js",
		output: {
			filename: "main.[hash].js",
			path: path.resolve(__dirname, "dist")
		},
		plugins: [
			new webpack.DefinePlugin(envKeys),
			new CleanWebpackPlugin(),
			new HtmlWebpackPlugin({
				template: "./src/index.html",
			}),
		],
		module: {
			rules: [
				{
					test: /\.(js|jsx)$/,
					exclude: /node_modules/,
					loader: 'babel-loader',
					query: {
		                presets: ["@babel/preset-env", "@babel/preset-react"]
		            }
				},
			],
		},
		devServer: {
			compress: true,
		},
	};
};
