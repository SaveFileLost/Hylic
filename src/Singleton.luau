local cache: {[string]: Singleton} = {}
local loaded: {[Singleton]: true} = {}

local function doNothing() end

local function getCachedSingleton(name: string)
	local singleton = cache[name]
	if singleton then return singleton end
	
	singleton = {
		Name = name,
		
		init = doNothing,
		start = doNothing,
	}
	cache[name] = singleton
	
	return singleton
end

local function new<T>(name: string)
	local singleton = getCachedSingleton(name)
	loaded[singleton] = true

	return singleton :: Singleton & T
end

return {
	New = new,
	Get = getCachedSingleton,
	
	Cache = cache,
	Loaded = loaded,
}