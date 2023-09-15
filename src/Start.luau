local Singletons = require(script.Parent.Singletons)
local Components = require(script.Parent.Components)

local hasStarted = false
local function start()
    assert(not hasStarted)
    hasStarted = true

    Components.Start()
    Singletons.Start()
end

return start