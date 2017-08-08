pins = { motion = 5, dht = 2, positiveLed = 4, negativeLed = 3, gas = 0 }

topics = {
	connectivity = '/connectivity',
	motion = '/motion',
	tempHum = '/temp-hum',
	gas = '/gas'
}

require('start')