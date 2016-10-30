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
		mqttInstance.publish(topics.motion, createMessage(nil, {
			motion = level	
		}))
	end)

	-- init humidity and temperature
	tmr.alarm(1, 10000, 1, function()
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

	-- init smoke detection
end

local setNotification = function (isSuccess)
	if ( isSuccess ) then
		gpio.write(pins.negativeLed, gpio.LOW)
		gpio.write(pins.positiveLed, gpio.HIGH)
	else
		gpio.write(pins.positiveLed, gpio.LOW)
		gpio.write(pins.negativeLed, gpio.HIGH)
	end
end

local initNotifications = function ()
	gpio.mode(pins.positiveLed, gpio.OUTPUT)
	gpio.mode(pins.negativeLed, gpio.OUTPUT)
	-- by default turn on the negative led
	setNotification(false)
end

local initApp = function (configDevice, configMqtt)
	-- wifi connection is ready
	setNotification(true)

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

return {
	initNotifications = initNotifications,
	initApp = initApp
}
