-- Local props
local pins = { motion = 5, dht = 2, positiveLed = 4, negativeLed = 3 }

local topics = {
	connectivity = "/connectivity",
	motion = "/motion",
	tempHum = "/temp-hum"
}

local MQTT = dofile("mqtt_client.lua")
local SENSORS = dofile("sensors.lua")

-- Methods

local setNotification = function (isSuccess)
	gpio.write(pins.negativeLed, ( isSuccess and 0 or 1 ))
	gpio.write(pins.positiveLed, ( isSuccess and 1 or 0 ))
end

local initNotifications = function ()
	gpio.mode(pins.positiveLed, gpio.OUTPUT)
	gpio.mode(pins.negativeLed, gpio.OUTPUT)
	setNotification(false) -- by default turn on the negative led
end

local onConnected = function ()
	print("MQTT connection established")
	setNotification(true)
	MQTT.publish(topics.connectivity, "online")
	SENSORS.init( pins, topics, MQTT.publish)
end

local onDisconnected = function ()
	print("MQTT connection lost")
	setNotification(false)
	tmr.delay(1000)
	node.restart()
end

local onMessageSent = function (topic, payload)
	print("Мessage sent")
	setNotification(true)
end

local onMessageFailed = function (topic, payload)
	print("Мessage failed")
	setNotification(false)
end

local initApp = function ()
	MQTT.init(  topics, -- topics
				onConnected, onDisconnected, -- connectivity status callbacks
				onMessageSent, onMessageFailed ) -- message status callbacks
end

-- Exposed methods
return {
	initNotifications = initNotifications,
	initApp = initApp
}
