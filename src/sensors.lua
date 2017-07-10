return function (pins, topics, publisher)
	local status, temp, humi
	local smokeValue

	-- init motion detection (PIR)
	gpio.mode(pins.motion, gpio.INPUT)
	gpio.trig(pins.motion, "both", function (motionValue)
		if (motionValue == 1) then
			print('Motion is detected!')
			coroutine.resume(publisher, topics.motion, motionValue, nil, motionValue)
		end
	end)

	-- init humidity and temperature sensor (DHT)
	tmr.alarm(2, 10000, 1, function()
		status, temp, humi = dht.read(pins.dht)
		
		if status == dht.OK then
			coroutine.resume(publisher, topics.tempHum, {
				temperature = temp,
				humidity = humi	
			}, nil, 1)
		elseif status == dht.ERROR_CHECKSUM then
			coroutine.resume(publisher, topics.tempHum, nil, "DHT_ERROR_CHECKSUM", 1)
		elseif status == dht.ERROR_TIMEOUT then
			coroutine.resume(publisher, topics.tempHum, nil, "DHT_ERROR_TIMEOUT", 1)
		end
	end)

	-- init gas sensor (MQ-2)
	tmr.alarm(3, 5000, 1, function ()
		smokeValue = math.floor(tonumber(adc.read(pins.gas)) / 1023 * 100) - 15
		coroutine.resume(publisher, topics.gas, smokeValue, nil, 1)
	end)
end