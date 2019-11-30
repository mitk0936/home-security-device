local wifi_helper = require('lib/wifi');
local file_helper = require('lib/file');
local sntp_helper = require('lib/sntp');

local constants = require('app/constants');
local init_main = require('app/main');

local config_is_ok, config = file_helper.read_json_file('static/config.json');

--[[
  Crashes, because: 
    1. old firmware from 23.02.2019 has issues with ssl
    2. new firmware has problems with nodemcu-tool, because changed interface of node.info()


    WORKS WITHOUT SSL FOR NOW -> TODO: change port in config.json
]]

if (config_is_ok) then
  local start_main = init_main(config, constants);

  wifi_helper.wifi_config_sta(config.wifi.ssid, config.wifi.pwd);

  wifi_helper.wifi_connect(
    config.wifi.ssid,
    2000,
    function (ip)
      print('Connected, IP is '..ip);

      sntp_helper.sync_time(
        { '0.bg.pool.ntp.org', '1.bg.pool.ntp.org', '0.pool.ntp.org' },
        function()
          start_main();
        end
      );
    end
  );
else
  print('Cannot open static/config.json');
end