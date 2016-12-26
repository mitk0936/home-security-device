local mqtt  = require("mqtt")
local MQTT_QUEUE = dofile("mqtt_queue_helper.lua")

-- create client
return function (topics) -- topics
	local mqttClient = mqtt.Client(CONFIG.device.id, 20, CONFIG.device.user, CONFIG.device.password)
	
	local lwtMessage = cjson.encode({ value = "offline" })
	mqttClient:lwt(CONFIG.device.id..topics.connectivity, lwtMessage, 2, 1)

	-- create publisher
	return function (onMessageSuccess, onMessageFail) -- message status callbacks
		local publisher = MQTT_QUEUE(mqttClient, onMessageSuccess, onMessageFail)

		-- connect
		return function (onConnect, onOffline) -- connectivity status callbacks
			mqttClient:connect(CONFIG.mqtt.address, CONFIG.mqtt.port, 0, 1, onConnect, onOffline)
			mqttClient:on("connect", function ()
				-- publish
				onConnect(function (topic, payload, error)
					local message = cjson.encode({
						value = payload,
						error = error
					})

					publisher(CONFIG.device.id..topic, message, 2, 1)
				end)
			end)
			
			mqttClient:on("offline", onOffline)
		end
	end
end