gpio.write(pins.negativeLed, 1)
gpio.write(pins.positiveLed, 0)

syncTime = function ()
	sntp.sync({
		'0.bg.pool.ntp.org',
		'1.bg.pool.ntp.org',
		'0.pool.ntp.org'
	}, function ()
		dispatch('timeSynced', nil, true)
	end, function (err, name)
		tmr.delay(2000)
		syncTime()
	end)
end

subscribe('configReady', function (config)
	package.loaded['start'] = nil

	local mqttClient = mqtt.Client(config.device.user, 20, config.device.user, config.device.password)
	local lwtMessage = cjson.encode({ value = 0 }) 	-- creating lwt message
	mqttClient:lwt(config.device.user..topics.connectivity, lwtMessage, 2, 1)

	dispatch('mqttClientReady', mqttClient, true)

	wifi.setmode(wifi.STATION)
	wifi.sta.config(config.wifi.ssid, config.wifi.password)
	wifi.sta.connect()

	tmr.alarm(1, 1500, 1, function()
		if wifi.sta.getip() == nil then
			print('Connecting...')
		else
			tmr.stop(1)
			print('Connected, IP is '..wifi.sta.getip())
			syncTime()
		end
	end)

	subscribe('timeSynced', function ()
		gpio.write(pins.negativeLed, 0)
		gpio.write(pins.positiveLed, 1)

		syncTime = nil


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

			package.loaded['main'] = nil
		end)

		mqttClient:connect(config.mqtt.address, config.mqtt.port, 1, 0)
	end)
end)