print('Start heap is: ', node.heap())

syncTime = function (onSuccess)
	sntp.sync({
		"0.bg.pool.ntp.org",
		"1.bg.pool.ntp.org",
		"0.pool.ntp.org"
	}, onSuccess, function (err, name)
		tmr.delay(2000)
		syncTime(onSuccess)
	end)
end

connectWifi = function (config, onConnected)
	wifi.setmode(wifi.STATION)
	wifi.sta.config(config.wifi.ssid, config.wifi.password)
	wifi.sta.connect()

	tmr.alarm(1, 1500, 1, function()
		if wifi.sta.getip() == nil then
			print("Connecting...")
		else
			tmr.stop(1)
			print("Connected, IP is "..wifi.sta.getip())
			onConnected()
		end
	end)
end

require("main")
print('after loading main heap is: ', node.heap())
coroutine.resume(main)

if file.open("config.json") then
	local config = cjson.decode(file.read())
	file.close()
	coroutine.resume(main, config)

	connectWifi(config, function ()
		syncTime(function ()
			coroutine.resume(main)
		end)
	end)
else
	print("Cannot read config.json")
	tmr.delay(20000)
	node.restart()
end