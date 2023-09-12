export type Kind<TInstance, TComponent, TArgs...> = {
	name: string,

	add: (instance: Instance & TInstance, TArgs...) -> TComponent,
	get: (instance: (Instance & TInstance)?) -> TComponent?,
}

export type Component<T> = {
	instance: Instance & T,
	isDestroyed: boolean?,
	isManaged: boolean,

	destroy: () -> (),
	onDestroy: () -> (),
}

return nil