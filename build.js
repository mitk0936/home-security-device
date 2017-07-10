/*
	Node scripts for building and configuring the hardware device.
	Used npm commands:
	
	npm run mkfs
	To clear the filesystem of the connected device.
	
	npm run upload
	npm run upload prod
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

/* setting default options, used by the NodeMCU-Tool */
const options = `--connection-delay 400 --optimize --baud 115200`

/*
	findPort - function which finds connected device on USB port,
	returns success callback and passes the port name to it.
	Throws an error if no devices are found, or more than 1 devices are connected
*/
const findPort = function (onSuccess) {
	const serialport = require('serialport')
	const portsFound = []

	serialport.list(function (err, ports) {
		if (err) {
			throw 'Error occured with finding connected device on USB port.'
		}

		ports.forEach(function(port) {
			console.log('Found device on ', port.comName)
			portsFound.push(port.comName)
		})

		switch (portsFound.length) {
			case 1:
				onSuccess(portsFound[0])
				break;
			case 0:
				throw 'No connected devices were found.'
				break;
			default:
				throw 'More than one devices were found.'
		}
	})
}

/*
	Command for clearing the device file system.
	Usage: npm run mkfs
*/
cli.command('mkfs').action(function () {
	cd(nodemcuToolPath);

	findPort(function (port) {
		require('child_process')
			.execSync(`node nodemcu-tool mkfs --port=${port}`, { stdio: 'inherit' })
	})
})

/*
	Command for uploading the source files.
	Usage: npm run upload
*/
cli.command('upload').action(function (cmd, env) {
	const prod = process.argv.indexOf('prod') > -1
	const compilePrefix = prod ? '--compile' : ''

	findPort(function (port) {
		var allFiles = ''

		ls('src/*.lua').forEach(function (filename) {
			allFiles += ` ${pathToSrc}/${filename}`
		})

		cd(nodemcuToolPath)

		require('child_process')
			.execSync(`node nodemcu-tool upload ${allFiles} ${compilePrefix} --port=${port} ${options}`, { stdio: 'inherit' })

		require('child_process')
			.execSync(`node nodemcu-tool upload ${pathToSrc}/init.lua --port=${port} ${options}`, { stdio: 'inherit' })
	})
})

/*
	Command running the script for uploading the config.json file on the hardware device.
	Usage: npm run config
*/
cli.command('config').action(function () {
	findPort(function (port) {
		cd(nodemcuToolPath)

		require('child_process')
			.execSync(`node nodemcu-tool upload ${pathToSrc}/src/config.json --port=${port} ${options}`, { stdio: 'inherit' })
	})
})

/*
	Command running the script for starting the lua terminal,
	to read data from the hardware device.
	Usage: npm start
*/
cli.command('start').action(function () {
	findPort(function (port) {
		cd(nodemcuToolPath)

		exec(`node nodemcu-tool reset --port=${port}`, function () {
			require('child_process')
				.execSync(`node nodemcu-tool terminal --port=${port}`, { stdio: 'inherit' })
		})
	})
})

/*
	TODO: implement a script for generating a key for
	crypting the data.
*/
cli.command('sign').action(function () {
	cd(nodemcuToolPath)

	var command = `node nodemcu-tool run sign.lua`

	exec('node nodemcu-tool reset', function () {
		require('child_process')
			.execSync(`node nodemcu-tool run sign.lua`, { stdio: 'inherit' })
	})
})

/*
	Handle execution of unknown commands.
*/
cli.command('*').action( function(c){
	console.error('Unknown command "' + c + '"')
	cli.outputHelp()
})

cli.parse(process.argv)
