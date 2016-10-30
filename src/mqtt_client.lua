-- Local props
local publisher
local mqttQHelper = dofile("mqtt_queue_helper.lua")
local deviceId
local keepAlive = 20 -- sec

-- Methods
local init = function ( configDevice, configMqtt, topics, -- configs
						createMessage,  -- message creator function
						onConnect, onOffline, -- connectivity status callbacks
						onMessageSuccess, onMessageFail ) -- message status callbacks

	deviceId = configDevice.id

	-- create client
	local mqttClient = mqtt.Client(configDevice.id, keepAlive, configDevice.user, configDevice.password)

	-- create publisher
	publisher = mqttQHelper(mqttClient, onMessageSuccess, onMessageFail)

	-- set lwt and connect to the server
	mqttClient:lwt(configDevice.id..topics.connectivity, createMessage(nil, "offline"), 1, 1)
	mqttClient:connect(configMqtt.address, configMqtt.port, 0, 1, onConnect, onOffline)

	-- listen for connect/disconnect
	mqttClient:on("connect", onConnect)
	mqttClient:on("offline", onOffline)
end

local publish = function (topic, payload)
	-- put the deviceId as a prefix to all topics
	publisher(deviceId..topic, payload, 1, 1)
end

-- Exposed methods
return {
	init = init,
	publish = publish
}
