local Components = require(script.Parent.Components)

local hasStarted = false
local function start()
	assert(not hasStarted)
	hasStarted = true

	Components.start()
end

return start