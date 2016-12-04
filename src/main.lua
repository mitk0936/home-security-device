-- Local props
local pins = {
	motion = 5,
	dht = 2,
	positiveLed = 4,
	negativeLed = 3
}

local topics = {
	connectivity = "/connectivity",
	motion = "/motion",
	tempHum = "/temp-hum"
}

local mqttInstance = dofile("mqtt_client.lua")

-- Methods
local createMessage = function (error, value)
	local message = {
		error = error,
		value = value
	}

	return cjson.encode(message)
end

local initSensors = function (configMqtt)

	-- init motion detection
	gpio.mode(pins.motion, gpio.INPUT)
	gpio.trig(pins.motion, "both", function (level) -- motion sensor watcher
		print("Motion: "..level)
		mqttInstance.publish(topics.motion, createMessage(nil, {
			motion = level	
		}))
	end)

	-- init humidity and temperature
	tmr.alarm(1, 30000, 1, function()
		status, temp, humi = dht.read(pins.dht)

		if status == dht.OK then
			mqttInstance.publish(topics.tempHum, createMessage(nil, {
				temperature = temp,
				humidity = humi	
			}))
		elseif status == dht.ERROR_CHECKSUM then
			mqttInstance.publish(topics.tempHum, createMessage("DHT error checksum"))
		elseif status == dht.ERROR_TIMEOUT then
			mqttInstance.publish(topics.tempHum, createMessage("DHT error timeout"))
		end
	end)

	-- TODO: init smoke detection
end

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
	mqttInstance.init(configDevice, configMqtt, topics, createMessage, function (client)
		print("MQTT connection established")
		setNotification(true)
		mqttInstance.publish(topics.connectivity, createMessage(nil, "online"))
		initSensors()
	end, function (client)
		print("MQTT connection lost")
		setNotification(false)
		tmr.delay(3000)
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
