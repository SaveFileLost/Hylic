local Components = require(script.Components)
local Singletons = require(script.Singletons)
local Types = require(script.Types)

export type Kind<TInstance, TComponent, TArgs...> = Types.Kind<TInstance, TComponent, TArgs...>
export type Component<T> = Types.Component<T>;
export type Singleton = Types.Singleton;

return {
	Singleton = Singletons.Singleton,
	getSingleton = Singletons.getSingleton,

	Kind = Components.Kind,
	getKind = Components.getKind,
	getAllComponents = Components.getAllComponents,
}