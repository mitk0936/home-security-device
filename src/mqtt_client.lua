local mqtt  = require("mqtt")
local createMessagesQueue = dofile("mqtt_queue_helper.lua")

-- create client
return function (config, topics) -- topics
	local mqttClient = mqtt.Client(config.device.id, 20, config.device.user, config.device.password)
	
	local lwtMessage = global.cjson.encode({ value = 0 })
	mqttClient:lwt(config.device.id..topics.connectivity, lwtMessage, 2, 1)

	-- create publisher
	return function (onMessageSuccess, onMessageFail) -- message status callbacks
		local publisher = createMessagesQueue(mqttClient, onMessageSuccess, onMessageFail)

		-- connect
		return function (onConnect, onOffline) -- connectivity status callbacks
			mqttClient:connect(config.mqtt.address, config.mqtt.port, 0, 1, onConnect, onOffline)
			mqttClient:on("offline", onOffline)

			mqttClient:on("connect", function ()	
				local publish = function (topic, payload, error, qos, retain)
					local message = global.cjson.encode({
						value = payload,
						timestamp = global.rtctime.get(),
						error = error
					})

					print('sending', topic, payload, error, qos, retain)
					publisher(config.device.id..topic, message, qos, retain)
				end

				-- publish
				onConnect(publish)
			end)
		end
	end
end