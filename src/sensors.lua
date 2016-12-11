local initSensors = function (pins, topics, publish)

	-- init motion detection
	gpio.mode(pins.motion, gpio.INPUT)
	gpio.trig(pins.motion, "both", function (level)
		print("Motion: "..level)
		publish(topics.motion, {
			motion = level	
		})
	end)

	-- init humidity and temperature
	tmr.alarm(1, 30000, 1, function()
		status, temp, humi = dht.read(pins.dht)

		if status == dht.OK then
			publish(topics.tempHum, {
				temperature = temp,
				humidity = humi	
			})
		elseif status == dht.ERROR_CHECKSUM then
			publish(topics.tempHum, nil, "DHT_ERROR_CHECKSUM")
		elseif status == dht.ERROR_TIMEOUT then
			publish(topics.tempHum, nil, "DHT_ERROR_TIMEOUT")
		end
	end)

	-- TODO: init smoke detection
end

local initSimulation = function (pins, topics, publish)
	print("Simulating sensors data: ")

	-- simulate motion detection
	tmr.alarm(0, 10000, 1, function ()
		publish(topics.motion, {
			motion = math.floor(math.random() * 2)
		})
	end)

	-- simulate humidity and temperature
	local dhtErrors = { "DHT_ERROR_CHECKSUM", "DHT_ERROR_TIMEOUT" }
	tmr.alarm(1, 30000, 1, function ()
		local error = dhtErrors[math.floor(math.random() * 10)]
		
		error and publish(topics.tempHum, nil, error)
		or publish(topics.tempHum, {
			temperature = math.floor(math.random() * 45),
			humidity = math.floor(math.random() * 45)
		})
	end)
end

local init = function (configDevice, pins, topics, publish)
	local initMethod =	configDevice.simulation and
						initSimulation or
						initSensors

	initMethod(pins, topics, publish)
end

return {
	init = init
}