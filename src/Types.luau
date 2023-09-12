export type Kind<TInstance, TComponent, TArgs...> = {
	name: string,

	add: (instance: Instance & TInstance, TArgs...) -> TComponent,
	get: (instance: Instance & TInstance) -> TComponent?,
	has: (instance: Instance & TInstance) -> boolean,
}

export type Component<T> = {
	instance: Instance & T,
	isDestroyed: boolean?,
	isManaged: boolean,

	destroy: () -> (),
	onDestroy: () -> (),
}

export type Singleton = {
	name: string,

	init: () -> (),
	start: () -> (),
}

return nil