local mqttClient;
local publisher;

-- callbacks
local onMessageFailed;

local init = function (cfg, onConnect, onOffline, messageSentSuccess, messageSentFail)
	mqttClient = mqtt.Client(cfg.deviceId, cfg.keepAliveInterval, cfg.user, cfg.password);

	publisher = dofile("mqtt_queue_helper.lua")(mqttClient)
	
	mqttClient:lwt(cfg.lwtTopic, cfg.lwtMessage, 1, 1);
	mqttClient:connect(cfg.serverAddress, cfg.port, 0, 1, onConnect, onOffline);

	mqttClient:on("connect", onConnect);
	mqttClient:on("offline", onOffline);

	onMessageFailed = messageSentFail;

	return mqttClient;
end

local publish = function (topic, payload)
	if pcall(function ()
		publisher(topic, payload, 1, 1);
	end) then
		print("Message sent ok");
	else
		print("Message sent problem");
		onMessageFailed(topic, payload);
	end
end

return {
	init = init,
	publish = publish
}
