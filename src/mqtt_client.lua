-- Local props
local publisher
local mqttQHelper = dofile("mqtt_queue_helper.lua")
local topicPrefix
local keepAlive = 20 -- sec

-- message creator function
local createMessage = function (value, error)
	local message = {
		value = value,
		error = error
	}

	return cjson.encode(message)
end

-- Methods
local init = function ( configDevice, configMqtt, topics, -- configs
						onConnect, onOffline, -- connectivity status callbacks
						onMessageSuccess, onMessageFail ) -- message status callbacks

	topicPrefix = configDevice.id

	-- create client
	local mqttClient = mqtt.Client(configDevice.id, keepAlive, configDevice.user, configDevice.password)

	-- create publisher
	publisher = mqttQHelper(mqttClient, onMessageSuccess, onMessageFail)

	-- set lwt and connect to the server
	mqttClient:lwt(topicPrefix..topics.connectivity, createMessage("offline"), 2, 1)
	mqttClient:connect(configMqtt.address, configMqtt.port, 0, 1, onConnect, onOffline)

	-- listen for connect/disconnect
	mqttClient:on("connect", onConnect)
	mqttClient:on("offline", onOffline)
end

local publish = function (topic, payload, error)
	local message = createMessage(payload, error)
	publisher(topicPrefix..topic, message, 2, 1)
end

-- Exposed methods
return {
	init = init,
	publish = publish
}
