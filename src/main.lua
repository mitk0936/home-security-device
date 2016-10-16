local configMqtt = {
	deviceId = "dev-123456",
	user = "test-device",
	password = "123456",
	serverAddress = "m21.cloudmqtt.com",
	port = 10247,
	keepAliveInterval = 20,
	lwtTopic = "/home-security",
	lwtMessage = "offline"
};

local configSensors = {
	motionPin = 5,
	motionTopic = "/home-security"
};

local configNotifications = {
	positiveLedPin = 4,
	negativeLedPin = 3
};

local mqttInstance = dofile("mqtt_client.lua");

local initSensors = function ()
	print("starting sensors");

	-- init motion detection
	gpio.mode(configSensors.motionPin, gpio.INPUT);
	-- motion sensor watcher
	gpio.trig(configSensors.motionPin, "both", function (level)
		print('Motion: '..level);

		mqttInstance.publish(configSensors.motionTopic, level);
		mqttInstance.publish(configSensors.motionTopic, "next");
	end);

	-- init humidity and temperature

	-- init smoke detection
end

local setNotification = function (isSuccess)
	print("notification");
	print(isSuccess);

	if ( isSuccess ) then
		gpio.write(configNotifications.positiveLedPin, gpio.HIGH);
		gpio.write(configNotifications.negativeLedPin, gpio.LOW);
	else
		gpio.write(configNotifications.positiveLedPin, gpio.LOW);
		gpio.write(configNotifications.negativeLedPin, gpio.HIGH);
	end
end

local initNotifications = function ()
	-- init led notifications
	gpio.mode(configNotifications.positiveLedPin, gpio.OUTPUT);
	gpio.mode(configNotifications.negativeLedPin, gpio.OUTPUT);

	-- by default we do not have a connection
	setNotification(false)
end

local initApp = function ()
	-- wifi connection is ready
	setNotification(true);

	-- init mqtt
	mqttInstance.init(configMqtt, function (client)
		print("mqtt connection established");
		setNotification(true);
		
		mqttInstance.publish(configSensors.motionTopic, "online");
		initSensors();

	end, function (client)
		print("mqtt connection lost");
		setNotification(false);
		tmr.delay(3000);
		node.restart();
	end, function (topic, payload)
		-- on message sent
		setNotification(true);
	end, function (topic, payload)
		-- on message fail
		setNotification(false);
	end);
end

return {
	initNotifications = initNotifications,
	initApp = initApp
}
