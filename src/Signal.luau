type Connection<T...> = {
	IsConnected: boolean,
	Callback: (T...) -> (),

	Disconnect: (self: Connection<T...>) -> ()
}

type Signal<T...> = {
	connectionSet: {Connection<T...>},

	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection<T...>,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection<T...>,
	Wait: (self: Signal<T...>) -> T...,
	Fire: (self: Signal<T...>, T...) -> (),

	Destroy: (self: Signal<T...>) -> ()
}

local connectionMeta = {}
connectionMeta.__index = connectionMeta

function connectionMeta:Disconnect()
	self.connectionSet[self] = nil
	self.IsConnected = false
end

local signalMeta = {}
signalMeta.__index = signalMeta

function signalMeta:Connect(callback)
	local connection = {
		connectionSet = self.connectionSet,

		IsConnected = true,
		Callback = callback,
	}
	setmetatable(connection, connectionMeta)

	self.connectionSet[connection] = true

	return connection
end

function signalMeta:Once(callback)
	local connection 
	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)

	return connection
end

function signalMeta:Wait()
	local thread = coroutine.running()

	self:Once(function(...)
		coroutine.resume(thread, ...)
	end)

	return coroutine.yield()
end

function signalMeta:Fire(...)
	for connection in self.connectionSet do
		connection.Callback(...)
	end
end

function signalMeta:Destroy()
	for connection in self.connectionSet do
		connection:Disconnect()
	end

	table.clear(self)
end

local function Signal<T...>()
	local signal = setmetatable({
		connectionSet = {}
	}, signalMeta)
	
	return signal :: Signal<T...>
end

return Signal