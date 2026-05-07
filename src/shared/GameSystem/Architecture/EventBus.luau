local EventBus = {}
local listeners = {}

function EventBus.Subscribe(eventName, callback)
	if not listeners[eventName] then
		listeners[eventName] = {}
	end
	table.insert(listeners[eventName], callback)
	print(string.format("[EventBus] Subscribed to '%s' (listeners: %d)", eventName, #listeners[eventName]))
end

function EventBus.Emit(eventName, payload)
	print(string.format("[EventBus] Emitted '%s'", eventName))
	if listeners[eventName] then
		for _, callback in pairs(listeners[eventName]) do
			task.spawn(callback, payload)
		end
	else
		warn(string.format("[EventBus] WARNING: No listeners registered for '%s'", eventName))
	end
end

return EventBus
