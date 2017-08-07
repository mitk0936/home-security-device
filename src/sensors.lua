local status, temp, humi
local smokeValue

-- init motion detection (PIR)
gpio.mode(pins.motion, gpio.INPUT)
gpio.trig(pins.motion, 'both', function (motionValue)
	if (motionValue == 1) then
		dispatch('publish', {
			topic = topics.motion,
			value = motionValue,
			error = nil,
			retain = motionValue -- retain only when motion is detected
		})
	end
end)

-- init humidity and temperature sensor (DHT)
tmr.alarm(2, 10000, 1, function()
	status, temp, humi = dht.read(pins.dht)
	
	if status == dht.OK then
		dispatch('publish', {
			topic = topics.tempHum,
			value = {
				temperature = temp,
				humidity = humi
			},
			error = nil,
			retain = 1
		})
	elseif status == dht.ERROR_CHECKSUM then
		dispatch('publish', {
			topic = topics.tempHum,
			value = nil,
			error = 'DHT_ERROR_CHECKSUM',
			retain = 1
		})
	elseif status == dht.ERROR_TIMEOUT then
		dispatch('publish', {
			topic = topics.tempHum,
			value = nil,
			error = 'DHT_ERROR_TIMEOUT',
			retain = 1
		})
	end
end)

-- init gas sensor (MQ-2)
tmr.alarm(3, 5000, 1, function ()
	smokeValue = math.floor(tonumber(adc.read(pins.gas)) / 1023 * 100) - 15
	dispatch('publish', {
		topic = topics.gas,
		value = smokeValue,
		error = nil,
		retain = 1
	})
end)