gpio.write(pins.negativeLed, 1)
gpio.write(pins.positiveLed, 0)

subscribe('configReady', function (config)
	local mqttClient = mqtt.Client(config.device.user, 20, config.device.user, config.device.password)
	local lwtMessage = cjson.encode({ value = 0 }) 	-- creating lwt message
	mqttClient:lwt(config.device.user..topics.connectivity, lwtMessage, 2, 1)

	dispatch('mqttClientReady', mqttClient, true)

	subscribe('timeSynced', function ()
		gpio.write(pins.negativeLed, 0)
		gpio.write(pins.positiveLed, 1)

		mqttClient:on('offline', node.restart)

		mqttClient:on('connect', function () -- on connection
			dispatch('publish', {
				topic = topics.connectivity,
				value = 1,
				error = nil,
				retain = 1
			})
			
			tmr.alarm(1, 3500, 1, function()
				tmr.stop(1)
				
				if (config.device.simulation) then
					require('simulation')
					print('after loading simulation heap is: ', node.heap())
				else
					require('sensors')
					print('after loading sensors heap is: ', node.heap())
				end
			end)
		end)

		mqttClient:connect(config.mqtt.address, config.mqtt.port, 1, 0)
	end)
end)