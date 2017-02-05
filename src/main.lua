local pins = { motion = 5, dht = 2, positiveLed = 4, negativeLed = 3, gas = 0 }

local topics = {
	connectivity = "/connectivity",
	motion = "/motion",
	tempHum = "/temp-hum"
}

local setNotification = function (isSuccess)
	global.gpio.write(pins.negativeLed, ( isSuccess and 0 or 1 ))
	global.gpio.write(pins.positiveLed, ( isSuccess and 1 or 0 ))
end

-- start
return function ()
	global.gpio.mode(pins.positiveLed, global.gpio.OUTPUT)
	global.gpio.mode(pins.negativeLed, global.gpio.OUTPUT)
	setNotification(false) -- by default turn on the negative led

	-- init mqtt configuration
	return function (config)
		local createClient = dofile("mqtt_client.lua")
		local createPublisher = createClient(config, topics)

		local connect = createPublisher(function ()
			print("Мessage sent")
			setNotification(true)
		end, function ()
			print("Мessage failed")
			setNotification(false)
		end)

		-- connect mqtt client
		return function ()
			connect(function (publish)
				print("MQTT connection established")
				setNotification(true)
				publish(topics.connectivity, 1, nil, 2, 1)

				local initSensors = dofile("sensors.lua")
				initSensors(config, pins, topics, publish) -- start sensors
			end, function ()
				print("MQTT connection lost")
				setNotification(false)
				global.tmr.delay(1000)
				global.node.restart()
			end)
		end
	end
end