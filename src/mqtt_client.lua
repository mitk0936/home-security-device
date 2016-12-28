local mqtt  = require("mqtt")
local createMessagesQueue = dofile("mqtt_queue_helper.lua")

-- create client
return function (config, topics) -- topics
	local mqttClient = mqtt.Client(config.device.id, 20, config.device.user, config.device.password)
	
	local lwtMessage = cjson.encode({ value = "offline" })
	mqttClient:lwt(config.device.id..topics.connectivity, lwtMessage, 2, 1)

	-- create publisher
	return function (onMessageSuccess, onMessageFail) -- message status callbacks
		local publish = createMessagesQueue(mqttClient, onMessageSuccess, onMessageFail)

		-- connect
		return function (onConnect, onOffline) -- connectivity status callbacks
			mqttClient:connect(config.mqtt.address, config.mqtt.port, 0, 1, onConnect, onOffline)

			mqttClient:on("offline", onOffline)
			mqttClient:on("connect", function ()
				
				-- publish
				onConnect(function (topic, payload, error)
					local message = cjson.encode({
						value = payload,
						error = error
					})

					publish(config.device.id..topic, message, 2, 1)
				end)
			end)
		end
	end
end