-- Local props
local pins = { motion = 5, dht = 2, positiveLed = 4, negativeLed = 3 }

local topics = {
	connectivity = "/connectivity",
	motion = "/motion",
	tempHum = "/temp-hum"
}

local mqttInstance = dofile("mqtt_client.lua")
local sensors = dofile("sensors.lua")

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

local initApp = function (configDevice, configMqtt)
	-- init mqtt
	mqttInstance.init(configDevice, configMqtt, topics, function (client)
		print("MQTT connection established")
		
		setNotification(true)
		mqttInstance.publish(topics.connectivity, "online")
		
		sensors.init( configDevice, pins, topics, mqttInstance.publish)
	end, function (client)
		print("MQTT connection lost")
		setNotification(false)
		tmr.delay(1000)
		node.restart()
	end, function (topic, payload)
		-- on message sent success
		setNotification(true)
	end, function (topic, payload)
		-- on message sent fail
		print("Мessage sent failed")
		setNotification(false)
	end)
end

-- Exposed methods
return {
	initNotifications = initNotifications,
	initApp = initApp
}
