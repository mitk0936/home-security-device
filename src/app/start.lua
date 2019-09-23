wifi_helper = require('lib/wifi');

local file_helper = require('lib/file');
local sntp_helper = require('lib/sntp');
local constants = require('app/constants');

local main = require('app/main');

local ok, config = file_helper.read_json_file('static/config.json');

if (ok) then
  main.configure(config);

  wifi_helper.wifi_config_sta(config.wifi.ssid, config.wifi.pwd);

  wifi_helper.wifi_connect(
    config.wifi.ssid,
    2000,
    function (ip)
      print('Connected, IP is '..ip);

      sntp_helper.sync_time(
        { '0.bg.pool.ntp.org', '1.bg.pool.ntp.org', '0.pool.ntp.org' },
        function()
          main.start(constants);
        end
      );
    end
  );
else
  print('Cannot open static/config.json');
end