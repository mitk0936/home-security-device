-- Reqiured Lua firmware modules
file  = require("file")
cjson = require("cjson")
tmr   = require("tmr")
wifi  = require("wifi")
gpio  = require("gpio")
mqtt  = require("mqtt")
dht   = require("dht")
node  = require("node")

dofile("utils.lua") -- global utils functions

local MAIN = dofile("main.lua")
MAIN.initNotifications()

if file.open("config.json") then
	CONFIG = cjson.decode(file.read())
	file.close()

	-- print_table(CONFIG)

	wifi.setmode(wifi.STATION)
	wifi.sta.config(CONFIG.wifi.ssid, CONFIG.wifi.password)
	wifi.sta.connect()

	tmr.alarm(1, 1500, 1, function()
		if wifi.sta.getip() == nil then
			print("Connecting...")
		else
			tmr.stop(1)
			print("Connected, IP is "..wifi.sta.getip())
			MAIN.initApp()
		end
	end)
else
	print("Cannot read config.json")
end
