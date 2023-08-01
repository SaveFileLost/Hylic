local Singletons = require(script.Singletons)
local Components = require(script.Components)

return {
	Singleton = Singletons.Singleton,
	getSingleton = Singletons.get,
	
	Component = Components.Component,
	addComponent = Components.add,
	getComponent = Components.get,
	hasComponent = Components.has,
	
	start = require(script.Start)
}