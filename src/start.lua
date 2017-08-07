print('Start heap is: ', node.heap())

pins = { motion = 5, dht = 2, positiveLed = 4, negativeLed = 3, gas = 0 }

topics = {
	connectivity = "/connectivity",
	motion = "/motion",
	tempHum = "/temp-hum",
	gas = "/gas"
}

require('event_dispatcher')
require("main")
require("publisher")

syncTime = function ()
	sntp.sync({
		"0.bg.pool.ntp.org",
		"1.bg.pool.ntp.org",
		"0.pool.ntp.org"
	}, function ()
		dispatch('timeSynced', nil, true)
	end, function (err, name)
		tmr.delay(2000)
		syncTime()
	end)
end

if file.open("config.json") then
	local config = cjson.decode(file.read())
	file.close()

	dispatch('configReady', config, true)

	wifi.setmode(wifi.STATION)
	wifi.sta.config(config.wifi.ssid, config.wifi.password)
	wifi.sta.connect()

	tmr.alarm(1, 1500, 1, function()
		if wifi.sta.getip() == nil then
			print("Connecting...")
		else
			tmr.stop(1)
			print("Connected, IP is "..wifi.sta.getip())
			syncTime()
		end
	end)
else
	print("Cannot read config.json")
	tmr.delay(20000)
	node.restart()
end