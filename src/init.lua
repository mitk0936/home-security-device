-- Global Lua firmware modules
global = {
	cjson = require("cjson"),
	tmr   = require("tmr"),
	gpio  = require("gpio"),
	node  = require("node"),
	rtctime = require("rtctime")
}

local file  = require("file")
local wifi  = require("wifi")
local sntp = require("sntp")

dofile("utils.lua")

local startMain = dofile("main.lua")
local configurateMqtt = startMain()

local syncTime = function (onSuccess)
	sntp.sync("0.pool.ntp.org", function ()
		print("time sync ready")
		onSuccess()
	end, function (err) -- time sync error callback
		syncTime(onSuccess)
	end)
end

if file.open("config.json") then
	local config = global.cjson.decode(file.read())
	-- print_table(config)
	file.close()

	local connectMqtt = configurateMqtt(config)

	wifi.setmode(wifi.STATION)
	wifi.sta.config(config.wifi.ssid, config.wifi.password)
	wifi.sta.connect()

	global.tmr.alarm(1, 1500, 1, function()
		if wifi.sta.getip() == nil then
			print("Connecting...")
		else
			global.tmr.stop(1)
			print("Connected, IP is "..wifi.sta.getip())
			print("Syncing time...")
			syncTime(connectMqtt)
		end
	end)
else
	print("Cannot read config.json")
end
