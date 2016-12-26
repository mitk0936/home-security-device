local pins = { motion = 5, dht = 2, positiveLed = 4, negativeLed = 3, gas = 0 }

local topics = {
	connectivity = "/connectivity",
	motion = "/motion",
	tempHum = "/temp-hum"
}

local setNotification = function (isSuccess)
	gpio.write(pins.negativeLed, ( isSuccess and 0 or 1 ))
	gpio.write(pins.positiveLed, ( isSuccess and 1 or 0 ))
end

return function ()
	gpio.mode(pins.positiveLed, gpio.OUTPUT)
	gpio.mode(pins.negativeLed, gpio.OUTPUT)
	setNotification(false) -- by default turn on the negative led

	-- connect
	return function ()
		local createClient = dofile("mqtt_client.lua")
		local createPublisher = createClient(topics)

		local connect = createPublisher(function ()
			print("Мessage sent")
			setNotification(true)
		end, function ()
			print("Мessage failed")
			setNotification(false)
		end)
		
		connect(function (publish)
			local initSensors = dofile("sensors.lua")

			print("MQTT connection established")
			setNotification(true)
			publish(topics.connectivity, "online")
			initSensors(pins, topics, publish)
		end, function ()
			print("MQTT connection lost")
			setNotification(false)
			tmr.delay(1000)
			node.restart()
		end)
	end
end