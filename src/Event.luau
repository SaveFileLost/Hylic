type Connection<T...> = {
	IsConnected: boolean,
	Callback: (T...) -> (),

	Disconnect: (self: Connection<T...>) -> ()
}

type Event<T...> = {
	connectionSet: {Connection<T...>},

	Connect: (self: Event<T...>, callback: (T...) -> ()) -> Connection<T...>,
	Once: (self: Event<T...>, callback: (T...) -> ()) -> Connection<T...>,
	Wait: (self: Event<T...>) -> T...,
	Run: (self: Event<T...>, T...) -> (),

	Destroy: (self: Event<T...>) -> ()
}

local connectionMeta = {}
connectionMeta.__index = connectionMeta

function connectionMeta:Disconnect()
	self.connectionSet[self] = nil
	self.IsConnected = false
end

local eventMeta = {}
eventMeta.__index = eventMeta

function eventMeta:Connect(callback)
	local connection = {
		connectionSet = self.connectionSet,

		IsConnected = true,
		Callback = callback,
	}
	setmetatable(connection, connectionMeta)

	self.connectionSet[connection] = true

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
	for connection in self.connectionSet do
		connection.Callback(...)
	end
end

function eventMeta:Destroy()
	for _, connection in self.connectionSet do
		connection:Disconnect()
	end

	table.clear(self)
end

local function Event<T...>()
	local event = setmetatable({
		connectionSet = {}
	}, eventMeta)
	
	return event :: Event<T...>
end

return Event