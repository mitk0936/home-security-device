-- reqiured modules
mqtt = require("mqtt")
gpio = require("gpio")
node = require("node")
wifi = require("wifi")
tmr = require("tmr")
dht = require("dht")
file = require("file")
cjson = require("cjson")

-- global utils functions
utils = dofile("utils.lua")

local Main = dofile("main.lua");

Main.initNotifications();

-- read config.json
-- get wifi credentials
-- get mqtt configurations

if file.open("config.json") then

	local config = cjson.decode(file.read())
	file.close()

	print("Configurations: ")
	utils.print_table(config)

	wifi.setmode(wifi.STATION);
	wifi.sta.config(config.wifi.ssid, config.wifi.password);
	wifi.sta.connect();

	tmr.alarm(1, 1500, 1, function()
		if wifi.sta.getip() == nil then
			print("Connecting...");
		else
			tmr.stop(1);
			print("Connected, IP is "..wifi.sta.getip());
			Main.initApp(config.device, config.mqtt);
		end
	end)
else
	print("Cannot read config.json")
end
