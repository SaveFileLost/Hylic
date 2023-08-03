local connectionMeta = {}
connectionMeta.__index = connectionMeta

function connectionMeta:Disconnect()
	self.IsConnected = false
end

local eventMeta = {}
eventMeta.__index = eventMeta

function eventMeta:Connect<T...>(callback: (T...) -> ())
	local connection = {
		IsConnected = true,
		Callback = callback,
	}
	setmetatable(connection, connectionMeta)

	table.insert(self.connections, connection)

	return connection
end

function eventMeta:Once<T...>(callback: (T...) -> ())
	local connection 
	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)

	return connection
end

function eventMeta:Wait<T...>(): T...
	local thread = coroutine.running()

	self:Once(function(...)
		coroutine.resume(thread, ...)
	end)

	return coroutine.yield()
end

function eventMeta:Run(...)
	for i = #self.connections, 1, -1 do
		local connection = self.connections[i]

		if connection.IsConnected then
			connection.Callback(...)
		else
			table.remove(self.connections, i)
		end
	end
end

function eventMeta:Destroy()
	for _, connection in self.connections do
		connection:Disconnect()
	end

	table.clear(self)
end

return function()
	local event = {connections = {}}
	setmetatable(event, eventMeta)

	return event
end