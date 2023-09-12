local Components = require(script.Parent.Components)
local Singletons = require(script.Parent.Singletons)

local hasStarted = false
local function start()
	assert(not hasStarted)
	hasStarted = true

	Components.start()
	Singletons.start()
end

return start