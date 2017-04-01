# Home-security-device

<h2>Wiring:<h2>

<p align="center">
	<img src="sketch/sketch.png" width="450"/>
</p>

# Building with node.js
	npm install

	npm run build (for uploading all lua source)
	npm run config (for uploading the config.json)
	npm start (for starting the nodemcu terminal)

# Binary with firmware:
	firmware/nodemcu-master-13-modules-2017-03-27-14-20-50-float.bin

# Nodemcu modules:
	adc, cjson, crypto, dht, file, gpio, mqtt, node, rtctime, sntp, tmr, wifi, tls

# Configuration:
	Before uploading config.json, add the configurations there for wifi, device and mqtt server

# Fritzing sketch:
	sketch.fzz