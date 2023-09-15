local Singletons = require(script.Singletons)
local Components = require(script.Components)

return {
	NewSingleton = Singletons.New,
	GetSingleton = Singletons.Get,

	NewKind = Components.NewKind,
	GetKind = Components.GetKind,
	GetAllComponents = Components.GetAllComponents,

	Event = require(script.Event),
	Start = require(script.start)
}