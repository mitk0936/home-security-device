local mqtt_client, _config;

local configure = function (config)
  _config = config
  mqtt_client = mqtt.Client(config.device.user, 20, config.device.user, config.device.password);
end

local start = function (constants)
  print('heap', node.heap());
  print('lwt', _config.device.user..constants.topics.connectivity, sjson.encode({ value = 0 }), 2, 1);

  mqtt_client:lwt(_config.device.user..constants.topics.connectivity, sjson.encode({ value = 0 }), 2, 1);

  mqtt_client:on('offline', node.restart);

  mqtt_client:on('connect', function () -- on connection

    print('connected', node.heap());

    local publish = require('app/publisher').start(mqtt_client, _config.device.user);

    publish(constants.topics.connectivity, 1, nil, 1, true);

    local sensors = require('app/sensors');
    sensors(constants, function (published_data)
      publish(
        published_data.topic,
        published_data.value,
        published_data.error,
        published_data.retain,
        published_data.topic == constants.topics.motion and false or true
      );
    end);

  end)

  print('connect', _config.mqtt.address, _config.mqtt.port);
  mqtt_client:connect(_config.mqtt.address, _config.mqtt.port);
end

return {
  configure = configure,
  start = start
};