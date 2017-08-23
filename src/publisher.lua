local queue = { }
local isSending = false
local message
local topic, value, error, retain
local send
local lastSent = {
	[topics.motion] = {},
	[topics.tempHum] = {},
	[topics.gas] = {}
}

subscribe('configReady', function (config)
	subscribe('mqttClientReady', function (mqttClient)
		local mqttPub = function (message, send)
			mqttClient:publish(message[1], message[2], message[3], message[4], send)
		end

		send = function ()
			collectgarbage()
			if #queue > 0 then
				message = table.remove(queue, 1)
				if (not pcall(mqttPub, message, send)) then
					print('Failed to send: ', message[1], message[2], message[3], message[4])
					queue[#queue + 1] = message
					send() -- continue the queue
				end
			else
				isSending = false
				collectgarbage()
				print('HEAP: ', node.heap())
			end
		end

		subscribe('publish', function (published)
			collectgarbage()
			
			if (cjson.encode(lastSent[published.topic]) ~= cjson.encode(published.value)) then
				lastSent[published.topic] = published.value -- save the new message

				message = cjson.encode({
					value = published.value,
					timestamp = rtctime.get(),
					error = published.error
				})

				queue[#queue + 1] = { config.device.user..published.topic, message, 2, published.retain }
				print('SENDING: ', config.device.user..published.topic, published.value, error, 2, published.retain)

				if not isSending then
					isSending = true
					send()
				end

				-- do not cache last motion message
				lastSent[topics.motion] = nil
				published = nil
			end
		end)
	end)
end)