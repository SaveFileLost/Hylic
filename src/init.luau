local Components = require(script.Components)
local Types = require(script.Types)
local start = require(script.start)

export type Kind<TInstance, TComponent, TArgs...> = Types.Kind<TInstance, TComponent, TArgs...>
export type Component<T> = Types.Component<T>;

return {
	Kind = Components.Kind,
	getKind = Components.getKind,
	getAllComponents = Components.getAllComponents,

	start = start
}