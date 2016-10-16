-- reqiured modules
mqtt = require("mqtt");
gpio = require("gpio");
node = require("node");
wifi = require("wifi");
tmr = require("tmr");
--dht = require("dht");

local Main = dofile("main.lua");

Main.initNotifications();

wifi.setmode(wifi.STATION);
wifi.sta.config("mitko-mobile","myphone1");
wifi.sta.connect();

tmr.alarm(1, 1500, 1, function()
	if wifi.sta.getip() == nil then
		print("Connecting...");
	else
		tmr.stop(1);
		print("Connected, IP is "..wifi.sta.getip());
		Main.initApp();
	end
end)
