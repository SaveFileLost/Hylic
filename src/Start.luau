local Singleton = require(script.Parent.Singleton)

local hasStarted = false

return function()
	assert(not hasStarted, `Hylic has already started`)
	hasStarted = true
	
	for _, singleton in Singleton.Cache do
		assert(Singleton.Loaded[singleton], `Singleton \"{singleton}\" was never created`)
		singleton.init()
	end
	
	for _, singleton in Singleton.Cache do
		singleton.start()
	end
end