require("publisher")
print('after loading publisher heap is: ', node.heap())

local pins = { motion = 5, dht = 2, positiveLed = 4, negativeLed = 3, gas = 0 }

local topics = {
	connectivity = "/connectivity",
	motion = "/motion",
	tempHum = "/temp-hum",
	gas = "/gas"
}

main = coroutine.create(function ()
	gpio.write(pins.negativeLed, 1)
	gpio.write(pins.positiveLed, 0)

	local config = coroutine.yield()

	local mqttClient = mqtt.Client(config.device.user, 20, config.device.user, config.device.password)
	local lwtMessage = cjson.encode({ value = 0 }) 	-- creating lwt message
	mqttClient:lwt(config.device.user..topics.connectivity, lwtMessage, 2, 1)

	print('after creating the mqtt client heap is: ', node.heap())
	coroutine.resume(publisher, topics, config.device.user, mqttClient)

	coroutine.yield() -- connected

	gpio.write(pins.negativeLed, 0)
	gpio.write(pins.positiveLed, 1)

	mqttClient:on("offline", node.restart)

	mqttClient:on("connect", function () -- on connection
		coroutine.resume(publisher, topics.connectivity, 1, nil, 1)
		
		tmr.alarm(1, 3500, 1, function()
			tmr.stop(1)
			
			if (config.device.simulation) then
				require("simulation")(pins, topics, publisher)
				print('after loading simulation heap is: ', node.heap())
			else
				require("sensors")(pins, topics, publisher)
				print('after loading sensorsc heap is: ', node.heap())
			end

			-- free the memory from init.lua
			syncTime, connectWifi, readConfig, config = nil
		end)
	end)

	mqttClient:connect(config.mqtt.address, config.mqtt.port, 1, 0)
end)