local status, temp, humi;
local smoke_value;

local start = function (constants, publish)
  -- init motion detection (PIR)
  gpio.mode(constants.pins.motion, gpio.INPUT);

  if adc.force_init_mode(adc.INIT_ADC)
  then
    print('Force restart to reinitialize ADC mode.');
    node.restart();
    return;
  end

  gpio.trig(constants.pins.motion, 'both', function (motion_value)
    if (motion_value == 1) then
      publish({
        topic = constants.topics.motion,
        value = motion_value,
        error = nil
      });
    end
  end)

  -- init humidity and temperature sensor (DHT)
  tmr.alarm(2, constants.intervals.temp_hum, 1, function()
    status, temp, humi = dht.read(constants.pins.dht)
    
    if status == dht.OK then
      publish({
        topic = constants.topics.temp_hum,
        value = {
          temperature = temp,
          humidity = humi
        },
        error = nil
      })
    elseif status == dht.ERROR_CHECKSUM then
      publish({
        topic = constants.topics.temp_hum,
        value = nil,
        error = 'DHT_ERROR_CHECKSUM'
      });
    elseif status == dht.ERROR_TIMEOUT then
      publish({
        topic = constants.topics.temp_hum,
        value = nil,
        error = 'DHT_ERROR_TIMEOUT'
      });
    end
  end)

  -- init gas sensor (MQ-2)
  tmr.alarm(3, constants.intervals.gas, 1, function ()
    smoke_value = math.floor(
      tonumber(adc.read(constants.pins.gas) / 1024) * 100
    );

    publish({
      topic = constants.topics.gas,
      value = smoke_value,
      error = nil
    });
  end)
end

return start;

