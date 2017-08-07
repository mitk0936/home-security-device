local callbacks = { }
local lastData = { }

subscribe = function (eventName, callback)
	eventName = tostring(eventName)

	if (type(callback) == 'function') then
		if (lastData[eventName] and lastData[eventName].called) then
			callback(lastData[eventName].data)
		end

		if (callbacks[eventName]) then
			callbacks[eventName][#callbacks[eventName] + 1] = callback
		else
			callbacks[eventName] = { callback }
		end
	end

end

dispatch = function (eventName, eventData)
	eventName = tostring(eventName)

	lastData[eventName] = {
		called = true,
		data = eventData
	}

	if (callbacks[eventName]) then
		for index, callback in pairs(callbacks[eventName]) do
			callback(eventData)
		end
	end
end