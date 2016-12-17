-- Local props
local publisher
local keepAlive = 20 -- sec

local MQTT_QUEUE = dofile("mqtt_queue_helper.lua")

-- Methods
local createMessage = function (value, error)
	local message = {
		value = value,
		error = error
	}

	return cjson.encode(message)
end

local init = function ( topics, -- topics
						onConnect, onOffline, -- connectivity status callbacks
						onMessageSuccess, onMessageFail ) -- message status callbacks

	-- create client
	local mqttClient = mqtt.Client(CONFIG.device.id, keepAlive, CONFIG.device.user, CONFIG.device.password)

	-- create publisher
	publisher = MQTT_QUEUE( mqttClient, onMessageSuccess, onMessageFail )

	-- set lwt and connect to the server
	mqttClient:lwt( CONFIG.device.id..topics.connectivity,
					createMessage("offline"), 2, 1 )
	
	mqttClient:connect( CONFIG.mqtt.address,
						CONFIG.mqtt.port, 0, 1,
						onConnect, onOffline )

	-- listen for connect/disconnect
	mqttClient:on("connect", onConnect)
	mqttClient:on("offline", onOffline)
end

local publish = function (topic, payload, error)
	local message = createMessage(payload, error)
	publisher(CONFIG.device.id..topic, message, 2, 1)
end

-- Exposed methods
return {
	init = init,
	publish = publish
}
