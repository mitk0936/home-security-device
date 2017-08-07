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
			topic  = published.topic
			value  = published.value
			error  = published.error
			retain = published.retain

			if (cjson.encode(lastSent[topic]) ~= cjson.encode(value)) then
				lastSent[topic] = value -- save the new message

				message = cjson.encode({
					value = value,
					timestamp = rtctime.get(),
					error = error
				})

				queue[#queue + 1] = { prefix..topic, message, qos, retain }
				print('sending', prefix..topic, value, error, qos, retain)
				
				if not isSending then
					isSending = true
					send()
				end

				-- do not cache last motion message
				lastSent[topics.motion] = nil
			else
				print('Refused to send data for '..topic..', due to bandwith optimizations.')
			end
		end)
	end)
end)