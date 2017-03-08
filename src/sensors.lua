local dht = require("dht")
local adc = require("adc")

local qos = 2

local initSensors = function (pins, topics, publish)

	-- init motion detection (PIR)
	global.gpio.mode(pins.motion, global.gpio.INPUT)
	global.gpio.trig(pins.motion, "both", function (motionValue)
		if (motionValue == 1) then
			print('Motion is detected!')
		end

		local retain = motionValue -- retain only when motion is detected
		local error = nil

		publish(topics.motion, motionValue, error, qos, retain) 
	end)

	-- init humidity and temperature sensor (DHT)
	global.tmr.alarm(1, 30000, 1, function()
		status, temp, humi = dht.read(pins.dht)

		local payload = nil
		local error = nil
		local retain = 1
		
		if status == dht.OK then
			publish(topics.tempHum, {
				temperature = temp,
				humidity = humi	
			}, error, qos, retain)
		elseif status == dht.ERROR_CHECKSUM then
			publish(topics.tempHum, payload, "DHT_ERROR_CHECKSUM", qos, retain)
		elseif status == dht.ERROR_TIMEOUT then
			publish(topics.tempHum, payload, "DHT_ERROR_TIMEOUT", qos, retain)
		end
	end)

	-- init gas sensor (MQ-2)
	-- global.tmr.alarm(2, 1200, 1, function ()
	-- 	print(adc.read(0))
	-- end)
end

local initSimulation = function (pins, topics, publish)
	print("Simulating sensors data!")

	-- simulate motion detection
	global.tmr.alarm(0, 5000, 1, function ()
		local motionValue = math.floor(math.random() * 2) -- 0 or 1

		local retain = motionValue -- retain only when motion is detected
		local error = nil
		
		publish(topics.motion, motionValue, error, qos, retain)
	end)

	-- simulate humidity and temperature sensor
	local dhtErrors = { "DHT_ERROR_CHECKSUM", "DHT_ERROR_TIMEOUT" }

	global.tmr.alarm(1, 30000, 1, function ()
		local payload = nil
		local error = dhtErrors[math.floor(math.random() * 10)]
		local retain = 1

		if (error) then
			publish(topics.tempHum, payload, error, qos, retain)
		else
			error = nil
			publish(topics.tempHum, {
				temperature = math.floor(math.random() * 100),
				humidity = math.floor(math.random() * 100)
			}, error, qos, retain)
		 end
	end)
end

return function (config, pins, topics, publish)
	local lastSent = {
		[topics.motion] = {},
		[topics.tempHum] = {}
		-- [topics.gas]
	}

	local optimizedPublish = function (topic, data, error, qos, retain)
		if (global.cjson.encode(lastSent[topic]) ~= global.cjson.encode(data)) then
			publish(topic, data, error, qos, retain)
			lastSent[topic] = data
		else
			print('Refused to send data for '..topic..', due to bandwith optimizations')
		end
	end

	local initMethod = ( config.device.simulation ) and initSimulation or initSensors
	initMethod(pins, topics, optimizedPublish)
end