local mqttClient
local publisher
local mqttQHelper = dofile("mqtt_queue_helper.lua");

local deviceId

local init = function (configDevice, configMqtt, createMessage, onConnect, onOffline, onMessageSuccess, onMessageFail)
	deviceId = configDevice.id

	mqttClient = mqtt.Client(configDevice.id, configMqtt.keepAliveInterval, configDevice.user, configDevice.password)

	publisher = mqttQHelper(mqttClient, onMessageSuccess, onMessageFail)
	
	mqttClient:lwt(configDevice.id..configMqtt.connectivityTopic, createMessage(nil, "offline"), 1, 1);
	mqttClient:connect(configMqtt.address, configMqtt.port, 0, 1, onConnect, onOffline);

	mqttClient:on("connect", onConnect);
	mqttClient:on("offline", onOffline);
end

local publish = function (topic, payload)
	publisher(deviceId..topic, payload, 1, 1)
end

return {
	init = init,
	publish = publish
}
