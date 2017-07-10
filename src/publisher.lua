publisher = coroutine.create(function (topics, prefix, client)
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

	local function send ()
		collectgarbage()
		print('heap size', node.heap())
		print('queue size', #queue)

		if #queue > 0 then
			message = table.remove(queue, 1)

			if (not pcall(function ()
				client:publish(message[1], message[2], message[3], message[4], send)
			end)) then
				print('Failed to send: ', message[1], message[2], message[3], message[4])
				queue[#queue + 1] = message
				send() -- continue the queue
			end
		else
			isSending = false
		end
	end

	while true do
		topic, value, error, retain = coroutine.yield()

		if (cjson.encode(lastSent[topic]) ~= cjson.encode(value)) then
			lastSent[topic] = value -- save the new message

			message = cjson.encode({
				value = value,
				timestamp = rtctime.get(),
				error = error
			})

			queue[#queue + 1] = { prefix..topic, message, qos, retain }
			print('sending', prefix..topic, value, error, qos, retain)

			topic, value, error, retain = nil
			
			if not isSending then
				isSending = true
				send()
			end

			-- do not cache last motion message
			lastSent[topics.motion] = nil
		else
			print('Refused to send data for '..topic..', due to bandwith optimizations.')
		end
	end
end)