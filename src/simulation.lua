-- initialize simulation of sensors
return function (pins, topics, publisher)
	print("Simulating sensors data!")

	local motionValue
	local dhtErrors = { dht.ERROR_CHECKSUM, dht.ERROR_TIMEOUT }
	local error
	local smokeGasConcentration

	-- simulate motion detection
	tmr.alarm(2, 10000, 1, function ()
		motionValue = math.floor(math.random() * 2) -- 0 or 1
		-- retain only when motion is detected 
		coroutine.resume(publisher, topics.motion, motionValue, nil, motionValue)
		motionValue = nil
	end)

	tmr.alarm(3, 10000, 1, function ()
		error = dhtErrors[math.floor(math.random() * 10)]

		if (error) then
			coroutine.resume(publisher, topics.tempHum, nil, error, 1)
		else
			coroutine.resume(publisher, topics.tempHum, {
				temperature = math.floor(math.random() * 100),
				humidity = math.floor(math.random() * 100)
			}, nil, 1)
		 end

		 error = nil
	end)

	-- simulating smoke sensor
	tmr.alarm(4, 10000, 1, function ()
		smokeGasConcentration = math.floor(math.random() * 100)
		coroutine.resume(publisher, topics.gas, smokeGasConcentration, nil, 1)
		smokeGasConcentration = nil
	end)
end