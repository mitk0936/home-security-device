local dht = require("dht")
local adc = require("adc")

local initSensors = function (pins, topics, publish)
	-- init motion detection (PIR)
	global.gpio.mode(pins.motion, global.gpio.INPUT)
	global.gpio.trig(pins.motion, "both", function (motionValue)
		if (motionValue == 1) then
			print('Motion is detected!')
		end

		publish(topics.motion, motionValue, nil, motionValue) 
	end)

	-- init humidity and temperature sensor (DHT)
	global.tmr.alarm(2, 30000, 1, function()
		local status, temp, humi = dht.read(pins.dht)
		print(temp, humi)
		
		if status == dht.OK then
			publish(topics.tempHum, {
				temperature = temp,
				humidity = humi	
			}, nil, 1)
		elseif status == dht.ERROR_CHECKSUM then
			publish(topics.tempHum, nil, "DHT_ERROR_CHECKSUM", 1)
		elseif status == dht.ERROR_TIMEOUT then
			publish(topics.tempHum, nil, "DHT_ERROR_TIMEOUT", 1)
		end
	end)

	-- init gas sensor (MQ-2)
	global.tmr.alarm(3, 4000, 1, function ()
		local smokeValue = math.floor(tonumber(adc.read(pins.gas)) / 1023 * 100)
		publish(topics.gas, smokeValue, nil, 1)
	end)
end

local initSimulation = function (pins, topics, publish)
	print("Simulating sensors data!")
	local sensorsInterval = 60000
	
	-- simulate motion detection
	global.tmr.alarm(2, sensorsInterval, 1, function ()
		local motionValue = math.floor(math.random() * 2) -- 0 or 1
		-- retain only when motion is detected
		publish(topics.motion, motionValue, nil, motionValue)
	end)

	-- simulate humidity and temperature sensor
	local dhtErrors = { "DHT_ERROR_CHECKSUM", "DHT_ERROR_TIMEOUT" }

	global.tmr.alarm(3, sensorsInterval, 1, function ()
		local error = dhtErrors[math.floor(math.random() * 10)]

		if (error) then
			publish(topics.tempHum, nil, error, 1)
		else
			publish(topics.tempHum, {
				temperature = math.floor(math.random() * 100),
				humidity = math.floor(math.random() * 100)
			}, nil, 1)
		 end
	end)

	global.tmr.alarm(4, sensorsInterval, 1, function ()
		local smokeGasConcentration = math.floor(math.random() * 100)
		publish(topics.gas, smokeGasConcentration, nil, 1)
	end)
end

-- init
return function (config, pins, topics, publish)
	-- table with data about last sent messages
	local lastSent = {
		[topics.motion] = {},
		[topics.tempHum] = {},
		[topics.gas] = {}
	}

	-- method for optimizing the sending of data
	local optimizedPublish = function (topic, data, error, retain)
		-- check if previous sent data to this topic is the same as the new one
		if (global.cjson.encode(lastSent[topic]) ~= global.cjson.encode(data)) then
			publish(topic, data, error, 2, retain) -- publish the new message
			lastSent[topic] = data -- save the new message
		else
			print('Refused to send data for '..topic..', due to bandwith optimizations.')
		end
	end

	local initMethod = ( config.device.simulation ) and initSimulation or initSensors
	initMethod(pins, topics, optimizedPublish)
end