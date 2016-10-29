local pins = {
	motion = 5,
	dht = 2,
	positiveLed = 4,
	negativeLed = 3
};

local createMessage = function (error, value)
	local message = {
		error = error,
		value = value
	}

	return cjson.encode(message)
end

local mqttInstance = dofile("mqtt_client.lua");

local initSensors = function (configMqtt)

	-- init motion detection
	gpio.mode(pins.motion, gpio.INPUT);
	gpio.trig(pins.motion, "both", function (level)
		-- motion sensor watcher
		mqttInstance.publish(configMqtt.motionTopic, createMessage(nil, {
			motion = level	
		}))
	end)

	-- init humidity and temperature
	tmr.alarm(1, 30000, 1, function()
		status, temp, humi, temp_dec, humi_dec = dht.read(pins.dht)

		if status == dht.OK then
			mqttInstance.publish(configMqtt.tempHumTopic, createMessage(nil, {
				temperature = temp,
				humidity = humi	
			}))
		elseif status == dht.ERROR_CHECKSUM then
			mqttInstance.publish(configMqtt.tempHumTopic, createMessage("DHT error checksum"))
		elseif status == dht.ERROR_TIMEOUT then
			mqttInstance.publish(configMqtt.tempHumTopic, createMessage("DHT error timeout"))
		end
	end)

	-- init smoke detection
end

local setNotification = function (isSuccess)
	if ( isSuccess ) then
		gpio.write(pins.positiveLed, gpio.HIGH);
		gpio.write(pins.negativeLed, gpio.LOW);
	else
		gpio.write(pins.positiveLed, gpio.LOW);
		gpio.write(pins.negativeLed, gpio.HIGH);
	end
end

local initNotifications = function ()
	-- init led notifications
	gpio.mode(pins.positiveLed, gpio.OUTPUT);
	gpio.mode(pins.negativeLed, gpio.OUTPUT);
	-- by default we do not have a connection
	setNotification(false)
end

local initApp = function (configDevice, configMqtt)
	-- wifi connection is ready
	setNotification(true)

	-- init mqtt
	mqttInstance.init(configDevice, configMqtt, createMessage, function (client)
		print("MQTT connection established");
		setNotification(true);
		
		mqttInstance.publish(configMqtt.connectivityTopic, createMessage(nil, "online"));
		initSensors(configMqtt);

	end, function (client)
		print("MQTT connection lost");
		setNotification(false);
		tmr.delay(3000);
		node.restart();
	end, function (topic, payload)
		-- on message sent success
		print("Message sent ok");
		setNotification(true);
	end, function (topic, payload)
		-- on message sent fail
		setNotification(false);
		print("Мessage sent failed")
	end)
end

return {
	initNotifications = initNotifications,
	initApp = initApp
}
