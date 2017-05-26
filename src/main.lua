local pins = { motion = 5, dht = 2, positiveLed = 4, negativeLed = 3, gas = 0 }

local topics = {
	connectivity = "/connectivity",
	motion = "/motion",
	tempHum = "/temp-hum",
	gas = "/gas"
}

--	Function called to turn on/off notification LED's
-- isSuccess -> boolean parameter for positive/negative LED
local turnLed = function (isSuccess)
	global.gpio.write(pins.negativeLed, ( isSuccess and 0 or 1 ))
	global.gpio.write(pins.positiveLed, ( isSuccess and 1 or 0 ))
end

-- initMain
return function ()
	global.gpio.mode(pins.positiveLed, global.gpio.OUTPUT)
	global.gpio.mode(pins.negativeLed, global.gpio.OUTPUT)
	turnLed(false) -- by default turn on the negative led

	-- configureMqtt
	return function (config)
		local createMqttClient = dofile("mqtt_client.lua")
		local createMqttPublisher = createMqttClient(config, topics)

		-- connect function is returned from the mqtt module,
		-- as result of created publisher
		local connect = createMqttPublisher(
			-- onMessageSent
			function ()
				turnLed(true)
				collectgarbage()
			end,
			-- onMessageFailed
			function ()
				print("Мessage failed sending...")
				turnLed(false)
			end
		)

		-- callback for established connection
		local connectSuccess = function (publish) 
			turnLed(true)
			-- telling the server that the device is online
			publish(topics.connectivity, 1, nil, 2, 1)

			-- wait 3.5 seconds before the initialization of the sensors,
			-- due to problems with heavy operations with cpu
			-- when establishing secure connection (TLS)
			global.tmr.alarm(1, 3500, 1, function()
				global.tmr.stop(1)
				-- initialization of the sensors.lua program
				dofile("sensors.lua")(config, pins, topics, publish)
			end)
		end

		-- callback for lost conenction
		local connectionLost = function ()
			turnLed(false)
			global.tmr.delay(1000)
			global.node.restart()
		end

		-- connectMQTT, last step called from the init.lua program
		return function ()
			connect(connectSuccess, connectionLost)
		end
	end
end