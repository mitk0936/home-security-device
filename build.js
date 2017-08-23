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
	
	npm run flash
	To flash the bin firmware to connected device (esptool.py is dependency)

	npm run sign
	To generate the key for crypting the data. Still not used. Will be done in the future.
*/
const cli = require('commander')
const prompt = require('prompt')
prompt.start();

require('shelljs/global')

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
			if (port.serialNumber || port.manufacturer) {
				console.log('Found device on ', port.comName)
				portsFound.push(port.comName)
			}
		})

		switch (portsFound.length) {
			case 1:
				onSuccess(portsFound[0])
				break
			case 0:
				throw 'No connected devices were found.'
				break
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
	cd(nodemcuToolPath)

	findPort(function (port) {
		require('child_process')
			.execSync(`node nodemcu-tool mkfs --port=${port}`, { stdio: 'inherit' })
	})
})

/*
	Command for uploading the source files.
	Usage: npm run upload
*/
cli.command('upload [prodFlag]').action(function (prodFlag) {
	const prod = !!prodFlag && !!~prodFlag.indexOf('prod')
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

		require('child_process')
			.execSync(`node nodemcu-tool fsinfo --port=${port}`, { stdio: 'inherit' })
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

		require('child_process')
			.execSync(`node nodemcu-tool fsinfo --port=${port}`, { stdio: 'inherit' })
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
	Command for flashing the firmware,
	accepts folder path and flashing mode as an arguements
*/
cli.command('flash [folder] [mode]').action(function (folder, mode) {
	const folderPath = folder || 'firmware'
	const flashMode = mode || 'qio'

	console.log('Finding binaries to flash...')
	
	const binariesFound = ls(`${folderPath}/*.bin`)

	if (binariesFound.length) {
		console.log('Please type the index of the binary you want to flash')
	}

	binariesFound.forEach(function (file, index) {
		console.log(`${index}) ${file}`)
	})

	prompt.get([{
		name: 'binary-flash-index',
		required: true
	}], function (err, result) {
		const selectedIndex = parseInt(result['binary-flash-index'])

		if (binariesFound[selectedIndex]) {
			console.log('Flashing: ' + binariesFound[selectedIndex], '...')

			findPort(function (port) {
				require('child_process')
					.execSync(`esptool.py --port ${port} erase_flash`, { stdio: 'inherit' })

				require('child_process')
					.execSync(`esptool.py --port ${port} write_flash -fm ${flashMode} 0x00000 ${binariesFound[selectedIndex]}`, { stdio: 'inherit' })
			})

		} else {
			console.error('Invalid binary index selected.')
		}
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
