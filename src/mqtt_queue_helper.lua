-- createPublisher
return function (client, onMessageSuccess, onMessageFail)
	local queue = { }
	local isSending = false

	local function send ()
		if #queue > 0 then
			local message = table.remove(queue, 1)

			if (not pcall(function()
				client:publish(message[1], message[2], message[3], message[4], function ()
					onMessageSuccess(message[1], message[2])
					send()
				end)
			end)) then
				onMessageFail(message[1], message[2])
				send() -- continue the queue
			end
		else
			isSending = false
		end
	end
	
	-- publish
	return function (topic, message, qos, retain)
		queue[#queue + 1] = { topic, message, qos, retain }
		
		if not isSending then
			isSending = true
			send()
		end
	end
end