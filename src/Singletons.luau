type Singleton = {
	Name: string,

	init: () -> (),
	start: () -> ()
}

local cache: {[string]: Singleton} = {}
local loaded: {[Singleton]: true} = {}

local function get(name: string)
	local singleton = cache[name]
	if singleton then return singleton end
	
	singleton = {
		Name = name,
		
		init = function() end,
		start = function() end,
	}
	cache[name] = singleton
	
	return singleton
end

local function new<T>(name: string)
	local singleton = get(name)
	loaded[singleton] = true

	return singleton :: Singleton & T
end

local function start()
	for _, singleton in cache do
		assert(loaded[singleton], `Singleton \"{singleton}\" was never created`)
		singleton.init()
	end
	
	for _, singleton in cache do
		singleton.start()
	end
end

return {
	New = new,
	Get = get,
	
	Start = start;
}