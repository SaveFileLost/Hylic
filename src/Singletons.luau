local cache = {}

local function getCachedSingleton(name: string)
	local singleton = cache[name]
	if singleton ~= nil then return singleton end
	
	singleton = {}
	cache[name] = singleton
	
	return singleton
end

local function Singleton(name: string)
	local singleton = getCachedSingleton(name)
	
	function singleton.init() end
	function singleton.start() end
	
	return singleton
end

return {
	Singleton = Singleton,
	get = getCachedSingleton,
	
	cache = cache,
}