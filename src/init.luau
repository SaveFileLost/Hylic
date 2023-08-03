local Singleton = require(script.Singleton)
local Component = require(script.Component)

return {
	Singleton = {
		Create = Singleton.Create,
		Get = Singleton.Get,
	},

	Component = {
		Kind = Component.Kind,
		Add = Component.Add,
		Get = Component.Get,
		All = Component.All,
	},

	Event = require(script.Event),
	Start = require(script.Start)
}