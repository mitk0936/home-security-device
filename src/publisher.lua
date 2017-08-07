subscribe('configReady', function (config)

	local prefix = config.device.user
	local queue = { }
	local isSending = false
	local qos = 2
	local message;

	local lastSent = {
		[topics.motion] = {},
		[topics.tempHum] = {},
		[topics.gas] = {}
	}

	local topic, value, error, retain

	subscribe('mqttClientReady', function (mqttClient)
		local mqttPub = function (message, send)
			mqttClient:publish(message[1], message[2], message[3], message[4], send)
		end

		local function send ()
			collectgarbage()
			print('heap size', node.heap())
			print('queue size', #queue)

			if #queue > 0 then
				message = table.remove(queue, 1)

				if (not pcall(mqttPub, message, send)) then
					print('Failed to send: ', message[1], message[2], message[3], message[4])
					queue[#queue + 1] = message
					send() -- continue the queue
				end
			else
				isSending = false
			end
		end

		subscribe('publish', function (published)
			if (cjson.encode(lastSent[published.topic]) ~= cjson.encode(published.value)) then
				lastSent[published.topic] = published.value -- save the new message

				message = cjson.encode({
					value = published.value,
					timestamp = rtctime.get(),
					error = published.error
				})

				queue[#queue + 1] = { prefix..published.topic, message, qos, published.retain }
				print('sending', prefix..published.topic, published.value, error, qos, published.retain)
				
				if not isSending then
					isSending = true
					send()
				end

				-- do not cache last motion message
				lastSent[topics.motion] = nil
			else
				print('Refused to send data for '..published.topic..', due to bandwith optimizations.')
			end
		end)
	end)
end)