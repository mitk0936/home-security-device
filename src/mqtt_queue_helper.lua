-- MQTT queuing publish helper (modified)
-- LICENSE: http://opensource.org/licenses/MIT
-- Vladimir Dronnikov <dronnikov@gmail.com>
do
	-- factory
	local make_publisher = function (client, on_message_success, on_message_fail)
		local queue = { }
		local is_sending = false

		local function send ()
			if #queue > 0 then
				local tp = table.remove(queue, 1)

				if pcall(function()
					client:publish(tp[1], tp[2], tp[3], tp[4], function ()
						on_message_success(tp[1], tp[2])
						send()
					end)
				end) then
					-- success callback is called from client:publish callback
					-- on_message_success(tp[1], tp[2])
					-- send()
				else
					on_message_fail(tp[1], tp[2]);
					send(); -- continue the queue
				end
				
			else
				is_sending = false
			end
		end
		
		return function (topic, message, qos, retain)
			queue[#queue + 1] = {topic, message, qos, retain}
			if not is_sending then
				is_sending = true
				send()
			end
		end
	end

	return make_publisher
end
