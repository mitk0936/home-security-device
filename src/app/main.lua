local init = function (config, constants)
  local mqtt_client = mqtt.Client(config.device.user, 20, config.device.user, config.device.password);

  local start = function ()
    print('heap', node.heap());
    print('lwt', config.device.user..constants.topics.connectivity, sjson.encode({ value = 0 }), 2, 1);

    mqtt_client:lwt(config.device.user..constants.topics.connectivity, sjson.encode({ value = 0 }), 2, 1);

    mqtt_client:on('offline', node.restart);

    -- on connection
    mqtt_client:on('connect', function ()
      print('connected', node.heap());

      local publish = require('app/publisher').start(mqtt_client, config.device.user);

      publish(constants.topics.connectivity, 1, nil, 1, false);

      local sensors = require('app/sensors');
      sensors(constants, function (published_data)
        local optimize_publish = published_data.topic ~= constants.topics.motion;
        
        publish(
          published_data.topic,
          published_data.value,
          published_data.error,
          published_data.retain,
          optimize_publish
        );
      end);

    end)

    print('connecting to mqtt broker: ', config.mqtt.address, config.mqtt.port);
    mqtt_client:connect(config.mqtt.address, config.mqtt.port);
  end

  return start;
end

return init;