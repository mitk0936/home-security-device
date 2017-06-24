local mqtt  = require("mqtt")

-- createClient
return function (config, topics) -- topics
	local mqttClient = mqtt.Client(config.device.user, 20, config.device.user, config.device.password)
	
	-- creating lwt message
	local lwtMessage = global.cjson.encode({ value = 0 })
	mqttClient:lwt(config.device.user..topics.connectivity, lwtMessage, 2, 1)

	-- createPublisher
	return function (onMessageSuccess, onMessageFail) -- message status callbacks
		local publisher = dofile("mqtt_queue_helper.lua")(mqttClient, onMessageSuccess, onMessageFail)

		-- connect
		return function (onConnect, onOffline) -- connectivity status callbacks
			mqttClient:connect(config.mqtt.address, config.mqtt.port, 1, 0, onConnect, onOffline)
			mqttClient:on("offline", onOffline)

			-- register connect callback
			mqttClient:on("connect", function ()	
				local publish = function (topic, payload, error, qos, retain)
					local message = global.cjson.encode({
						value = payload,
						timestamp = global.rtctime.get(),
						error = error
					})

					print('sending', topic, payload, error, qos, retain)
					print('heap', global.node.heap())

					-- calling the publisher helper
					publisher(config.device.user..topic, message, qos, retain)
				end

				-- publish
				onConnect(publish)
			end)
		end
	end
end