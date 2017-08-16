print("Simulating sensors data!")
-- initialize simulation of sensors
local motionValue
local dhtErrors = { dht.ERROR_CHECKSUM, dht.ERROR_TIMEOUT }
local error
local smokeGasConcentration

local simulate = function ()
	-- simulate PIR
	motionValue = math.floor(math.random() * 2) -- 0 or 1
	dispatch('publish', {
		topic = topics.motion,
		value = motionValue,
		error = nil,
		retain = motionValue -- retain only when motion is detected
	})

	-- simulate DHT11
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

	-- simulating smoke sensor
	smokeGasConcentration = math.floor(math.random() * 100)
	dispatch('publish', {
		topic = topics.gas,
		value = smokeGasConcentration,
		error = nil,
		retain = 1
	})
end

local simulateInterval = tmr.create()
simulateInterval:register(2000, tmr.ALARM_AUTO, simulate)
simulateInterval:start()