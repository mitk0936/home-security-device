print('Initial heap is: ', node.heap())

require('event_dispatcher')
require('main')
require('publisher')

if (file.open('config.json')) then
	local config = cjson.decode(file.read())
	file.close()
	dispatch('configReady', config, true)
else
	print('Cannot read config.json')
	tmr.delay(20000)
	node.restart()
end