local Singleton = require(script.Singleton)
local Component = require(script.Component)

return {
	Singleton = {
		New = Singleton.New,
		Get = Singleton.Get,
	},

	Component = {
		NewKind = Component.NewKind,
		GetKind = Component.GetKind,

		All = Component.All,
	},

	Event = require(script.Event),
	Start = require(script.Start)
}