gpio.write(pins.negativeLed, 1)
gpio.write(pins.positiveLed, 0)

local syncTime = function (onError, onSuccess)
	sntp.sync({ '0.bg.pool.ntp.org', '1.bg.pool.ntp.org', '0.pool.ntp.org' }, onSuccess, onError)
end

subscribe('configReady', function (config)
	package.loaded['start'] = nil
	package.loaded['init'] = nil

	local mqttClient = mqtt.Client(config.device.user, 20, config.device.user, config.device.password)
	local lwtMessage = cjson.encode({ value = 0 }) 	-- creating lwt message
	mqttClient:lwt(config.device.user..topics.connectivity, lwtMessage, 2, 1)

	dispatch('mqttClientReady', mqttClient, true)

	wifi.setmode(wifi.STATION)
	wifi.sta.config(config.wifi.ssid, config.wifi.password)
	wifi.sta.connect()

	local connect = tmr.create()
	connect:register(1500, tmr.ALARM_AUTO, function (t)
		if wifi.sta.getip() == nil then
			print('Connecting...')
		else
			print('Connected, IP is '..wifi.sta.getip())
			t:unregister()
			syncTime(syncTime, function ()
				dispatch('timeSynced', nil, true)
			end)
		end
	end)
	connect:start()

	subscribe('timeSynced', function ()
		gpio.write(pins.negativeLed, 0)
		gpio.write(pins.positiveLed, 1)
		collectgarbage()

		syncTime = nil

		mqttClient:on('offline', node.restart)
		mqttClient:on('connect', function () -- on connection
			dispatch('publish', {
				topic = topics.connectivity,
				value = 1,
				error = nil,
				retain = 1
			})
			
			local waitAuth = tmr.create()
			waitAuth:register(3500, tmr.ALARM_SINGLE, function()
				if (config.device.simulation) then
					require('simulation')
					print('after loading simulation heap is: ', node.heap())
				else
					require('sensors')
					print('after loading sensors heap is: ', node.heap())
				end

				package.loaded['main'] = nil
				collectgarbage()
			end)
			waitAuth:start()
		end)

		mqttClient:connect(config.mqtt.address, config.mqtt.port, 1, 0)
	end)
end)