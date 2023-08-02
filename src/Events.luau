local connectionMeta = {}
connectionMeta.__index = connectionMeta

function connectionMeta:disconnect()
	self.connected = false
end

local eventMeta = {}
eventMeta.__index = eventMeta

function eventMeta:connect(callback)
	local connection = {
		isConnected = true,
		callback = callback,
	}
	setmetatable(connection, connectionMeta)

	table.insert(self._connections, connection)

	return connection
end

function eventMeta:once(callback)
	local connection 
	connection = self:connect(function(...)
		connection:disconnect()
		callback(...)
	end)

	return connection
end

function eventMeta:wait()
	local thread = coroutine.running()

	self:once(function(...)
		coroutine.resume(thread, ...)
	end)

	return coroutine.yield()
end

function eventMeta:run(...)
	for i = #self._connections, 1, -1 do
		local connection = self._connections[i]

		if connection.isConnected then
			connection.callback(...)
		else
			table.remove(self._connections, i)
		end
	end
end

function eventMeta:delete()
	for _, connection in self._connections do
		connection:disconnect()
	end

	table.clear(self)
end

return function()
	local event = {_connections = {}}
	setmetatable(event, eventMeta)

	return event
end