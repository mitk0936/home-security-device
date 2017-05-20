/*
	Node scripts for building and configuring the hardware device.
	Used npm commands:
	
	npm run upload
	To take all the lua source code from the src/ folder and to upload it on the connected microcontroller.
	
	npm run config
	To upload the config.json file with the prepared system configurations.

	npm start
	To start the lua terminal inside the console, reading prints from the connected hardware device.

	npm run sign
	To generate the key for crypting the data. Still not used. Will be done in the future.
*/
const cli = require('commander');
require('shelljs/global');

const nodemcuToolPath = 'node_modules/nodemcu-tool/bin'
const pathToSrc = '../../..'

// setting default options, used by the NodeMCU-Tool
const options = '--connection-delay 200 --optimize --baud 115200'

/*
	Command for uploading the source files.
	Usage: npm run upload
*/
cli.command('upload').action(function () {
	var allFiles = ''

	ls('src/*.lua').forEach(function (filename) {
		allFiles += ` ${pathToSrc}/${filename}`
	})

	cd(nodemcuToolPath);
	
	exec('node nodemcu-tool reset', function () {
		require('child_process')
			.execSync(`node nodemcu-tool upload ${allFiles} ${options}`, {stdio: 'inherit'});
	})
})

/*
	Command running the script for uploading the config.json file on the hardware device.
	Usage: npm run config
*/
cli.command('config').action(function () {
	cd(nodemcuToolPath);
	exec('node nodemcu-tool reset', function () {
		require('child_process')
			.execSync(`node nodemcu-tool upload ${pathToSrc}/src/config.json ${options}`, {stdio: 'inherit'})
	})
})

/*
	Command running the script for starting the lua terminal,
	to read data from the hardware device.
	Usage: npm start
*/
cli.command('start').action(function () {
	cd(nodemcuToolPath);

	require('child_process')
		.execSync('node nodemcu-tool terminal', {stdio: 'inherit'})
})

/*
	TODO: implement a script for generating a key for
	crypting the data.
*/
cli.command('sign').action(function () {
	cd(nodemcuToolPath);

	var command = `node nodemcu-tool run sign.lua`

	exec('node nodemcu-tool reset', function () {
		require('child_process')
			.execSync(`node nodemcu-tool run sign.lua`, {stdio: 'inherit'})
	})
})

/*
	Handle running of unknown commands.
*/
cli.command('*').action( function(c){
	console.error('Unknown command "' + c + '"')
	cli.outputHelp();
})

cli.parse(process.argv)
