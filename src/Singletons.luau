local Types = require(script.Parent.Types)
local doNothing = require(script.Parent.doNothing)

local cachedMap: {[string]: Types.Singleton} = {}
local loadedSet: {[Types.Singleton]: true} = {}

local function getSingleton(name: string)
	local singleton = cachedMap[name]
	if singleton then return singleton end
	
	singleton = {
		Name = name,
		
		init = doNothing,
		start = doNothing,
	}
	cachedMap[name] = singleton
	
	return singleton
end

local function Singleton<TSingleton>(name: string): Types.Singleton & TSingleton
	local singleton = getSingleton(name)
	loadedSet[singleton] = true

	return singleton
end

local function start()
	for _, singleton in cachedMap do
		assert(loadedSet[singleton], `Singleton \"{singleton}\" was never created`)
		singleton.init()
	end
	
	for _, singleton in cachedMap do
		singleton.start()
	end
end

return {
	Singleton = Singleton,
	getSingleton = getSingleton,
	
	start = start
}