local Singletons = require(script.Singletons)
local Components = require(script.Components)

return {
	Singleton = Singletons.New,
	GetSingleton = Singletons.Get,

	Kind = Components.NewKind,
	GetKind = Components.GetKind,
	GetAllComponents = Components.GetAllComponents,

	Signal = require(script.Signal),
	Start = require(script.start)
}