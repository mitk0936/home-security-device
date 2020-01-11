local init_leds = function(constants)
  gpio.mode(constants.pins.positiveLed, gpio.OUTPUT);
  gpio.mode(constants.pins.negativeLed, gpio.OUTPUT);
  
  gpio.write(constants.pins.positiveLed, 0);
  gpio.write(constants.pins.negativeLed, 1);

  return {
    positive = function ()
      gpio.write(constants.pins.positiveLed, 1);
      gpio.write(constants.pins.negativeLed, 0);
    end
  };
end

local init = function (config, constants)
  local mqtt_client = mqtt.Client(config.device.user, 20, config.device.user, config.device.password);
  local leds = init_leds(constants);

  local start = function ()
    mqtt_client:lwt(config.device.user..constants.topics.connectivity, sjson.encode({ value = 0 }), 2, 1);

    mqtt_client:on('offline', node.restart);

    -- on connection
    mqtt_client:on('connect', function ()
      print('MQTT connected');
      print('heap: ', node.heap());

      leds.positive();

      local startMqttPublisher = require('app/publisher');
      local publish = startMqttPublisher(mqtt_client, config.device.user);

      publish(constants.topics.connectivity, 1, nil, 1, false);

      local sensors = require('app/sensors');
      
      sensors(constants, function (sensor_data)
        local optimize_publish = sensor_data.topic ~= constants.topics.motion;
        local retain = 1;

        if (sensor_data.topic == constants.topics.motion) then
          retain = sensor_data.value;
        end
        
        publish(
          sensor_data.topic,
          sensor_data.value,
          sensor_data.error,
          retain,
          optimize_publish
        );
      end);
    end)

    print('Connecting to mqtt broker');
    print('address', config.mqtt.address);
    print('port', config.mqtt.port);

    mqtt_client:connect(config.mqtt.address, config.mqtt.port);
  end

  return start;
end

return init;