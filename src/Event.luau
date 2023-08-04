local connectionMeta = {}
connectionMeta.__index = connectionMeta

function connectionMeta:Disconnect()
	self.IsConnected = false
end

local eventMeta = {}
eventMeta.__index = eventMeta

function eventMeta:Connect(callback)
	local connection = {
		IsConnected = true,
		Callback = callback,
	}
	setmetatable(connection, connectionMeta)

	table.insert(self.connections, connection)

	return connection
end

function eventMeta:Once(callback)
	local connection 
	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)

	return connection
end

function eventMeta:Wait()
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

type Connection<T...> = {
	IsConnected: boolean,
	Callback: (T...) -> (),

	Disconnect: (self: Connection<T...>) -> ()
}

type Event<T...> = {
	connections: {Connection<T...>},

	Connect: (self: Event<T...>, callback: (T...) -> ()) -> Connection<T...>,
	Once: (self: Event<T...>, callback: (T...) -> ()) -> Connection<T...>,
	Wait: (self: Event<T...>) -> T...,
	Run: (self: Event<T...>, T...) -> (),

	Destroy: (self: Event<T...>) -> ()
}

return function<T...>()
	local event = setmetatable({connections = {}}, eventMeta)
	return event :: Event<T...>
end