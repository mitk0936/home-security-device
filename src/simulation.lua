print("Simulating sensors data!")
-- initialize simulation of sensors
local motionValue
local dhtErrors = { dht.ERROR_CHECKSUM, dht.ERROR_TIMEOUT }
local error
local smokeGasConcentration

-- simulate motion detection
tmr.alarm(2, 14000, 1, function ()
	motionValue = math.floor(math.random() * 2) -- 0 or 1
	dispatch('publish', {
		topic = topics.motion,
		value = motionValue,
		error = nil,
		retain = motionValue -- retain only when motion is detected
	})
end)

tmr.alarm(3, 10000, 1, function ()
	error = dhtErrors[math.floor(math.random() * 10)]

	if (error) then
		dispatch('publish', {
			topic = topics.tempHum,
			value = nil,
			error = error,
			retain = 1
		})
	else
		dispatch('publish', {
			topic = topics.tempHum,
			value = {
				temperature = math.floor(math.random() * 100),
				humidity = math.floor(math.random() * 100)
			},
			error = nil,
			retain = 1
		})
	 end
end)

-- simulating smoke sensor
tmr.alarm(4, 5000, 1, function ()
	smokeGasConcentration = math.floor(math.random() * 100)
	dispatch('publish', {
		topic = topics.gas,
		value = smokeGasConcentration,
		error = nil,
		retain = 1
	})
end)