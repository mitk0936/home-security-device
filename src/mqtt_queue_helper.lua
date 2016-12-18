-- MQTT queuing publish helper (modified)
-- LICENSE: http://opensource.org/licenses/MIT
-- Vladimir Dronnikov <dronnikov@gmail.com>
do
	-- factory
	local publish = function (client, onMessageSuccess, onMessageFail)
		local queue = { }
		local isSending = false

		local function send ()
			if #queue > 0 then
				local tp = table.remove(queue, 1)

				if (not pcall(function()
					client:publish(tp[1], tp[2], tp[3], tp[4], function ()
						onMessageSuccess(tp[1], tp[2])
						send()
					end)
				end)) then
					onMessageFail(tp[1], tp[2])
					send() -- continue the queue
				end
			else
				isSending = false
			end
		end
		
		return function ( topic, message, qos, retain )
			queue[#queue + 1] = { topic, message, qos, retain }
			
			if not isSending then
				isSending = true
				send()
			end
		end
	end

	return publish
end
