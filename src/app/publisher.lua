local start = function (mqtt_client, prefix)
  local queue = {};
  local is_sending = false;
  local last_sent = {};
  local messages_topic_prefix = prefix or '';
  local send;

  local mqtt_pub = function (message, on_complete)
    mqtt_client:publish(message.topic, message.text, message.qos, message.retain, on_complete);
  end

  send = function ()
    if (#queue > 0) then
      local message = table.remove(queue, 1);
      print('Message queue size', #queue);

      if (not pcall(mqtt_pub, message, function ()
        print('Message is sent to: ', message.topic);
        send();
      end)) then
        print('Failed to send: ', message.topic, message.text);
        queue[#queue + 1] = message;
        send();
      end
    else
      is_sending = false;
      collectgarbage();
      print('HEAP: ', node.heap());
    end
  end

  --publish
  return function (topic, value, error, retain, optimize_publish)
    local message = sjson.encode({
      value = value,
      timestamp = rtctime.get(),
      error = error
    });

    if (optimize_publish) then
      last_sent[topic] = last_sent[topic] or {};

      if (sjson.encode(last_sent[topic]) == sjson.encode({ value = value })) then
        return;
      else
        last_sent[topic] = { value = value };
      end
    end

    queue[#queue + 1] = {
      topic = messages_topic_prefix..topic,
      text = message,
      qos = 2,
      retain = retain
    };

    if (not is_sending) then
      is_sending = true;
      send();
    end
  end
end

return start;