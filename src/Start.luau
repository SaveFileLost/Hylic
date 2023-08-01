local Singletons = require(script.Parent.Singletons)

local hasStarted = false

return function()
	assert(not hasStarted, `Hylic has already started`)
	hasStarted = true
	
	for _, singleton in Singletons.cache do
		singleton.init()
	end
	
	for _, singleton in Singletons.cache do
		singleton.start()
	end
end