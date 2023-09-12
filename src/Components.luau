local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Types = require(script.Parent.Types)
local doNothing = require(script.Parent.doNothing)
local unimplemented = require(script.Parent.unimplemented)

local MANAGED_TAG = `_HC_MANAGED_{if RunService:IsServer() then "SV" else "CL"}`

type ComponentSet = { [Types.Component<Instance>]: true }
type AnyKind = Types.Kind<Instance, Types.Component<Instance>, any>

type InstanceTable = {
	kinds: { [string]: ComponentSet },
	all: ComponentSet,
}

local kindCache: { [string]: AnyKind } = {}
local definedKindSet: {[AnyKind]: true} = {}
local instanceTables: { [Instance]: InstanceTable } = {}

local function clearInstance(instance)
	local instanceTable = instanceTables[instance]

	-- Explicitly deleting components could have cleaned this instance already
	if not instanceTable then return end

	for component in instanceTable.all do
		if not component.isManaged then continue end

		component.destroy()
	end
end

local function getOrCreateInstanceTable(instance: Instance): InstanceTable
	local instanceTable = instanceTables[instance]
	if instanceTable then return instanceTable end

	instanceTable = {
		kinds = {},
		all = {},
	}
	instanceTables[instance] = instanceTable

	CollectionService:AddTag(instance, MANAGED_TAG)

	return instanceTable
end

local function getOrCreateKindTable(instanceTable: InstanceTable, kindName: string): ComponentSet
	local kindTable = instanceTable.kinds[kindName]
	if kindTable then return kindTable end

	kindTable = {}
	instanceTable.kinds[kindName] = kindTable

	return kindTable
end

local function getKind(name: string): Types.Kind<Instance, Types.Component<Instance>, any>
	local kind = kindCache[name]
	if not kind then
		kind = {
			name = name,

			add = unimplemented,
			get = unimplemented,
		}

		kindCache[name] = kind
	end

	return kind
end

local function Kind<TInstance, TComponent, TArgs...>(
	name: string,
	initializer: (TComponent, TArgs...) -> TComponent
): Types.Kind<TInstance, TComponent, TArgs...>
	local this = getKind(name)
	assert(not definedKindSet[this], `Kind {name} is already defined`)
	definedKindSet[this] = true

	function this.add(instance, ...)
		assert(instance:IsDescendantOf(game), `Can't add components to non-parented instance`)

		local instanceTable = getOrCreateInstanceTable(instance)
		local kindTable = getOrCreateKindTable(instanceTable, name)

		local component = {
			instance = instance,
			isDestroyed = false,
			isManaged = true,

			onDestroy = doNothing,
		} :: Types.Component<TInstance>

		function component.destroy()
			if component.isDestroyed then return end
			component.isDestroyed = true

			component.onDestroy()

			kindTable[component] = nil
			instanceTable.all[component] = nil

			if not next(kindTable) then instanceTable.kinds[name] = nil end

			if not next(instanceTable.kinds) then
				instanceTables[instance] = nil
				instance:RemoveTag(MANAGED_TAG)
			end
		end

		initializer(component, ...)

		return component
	end

	function this.get(instance)
		if not instance then return nil end

		local instanceTable = instanceTables[instance]
		local kindTable = if instanceTable then instanceTable.kinds[name] else nil

		return if kindTable then next(kindTable) else nil
	end

	return this
end

local function getAllComponents<T>(instance: Instance & T): { Types.Component<T> }
	local instanceTable = instanceTables[instance]
	if not instanceTable then return {} end

	local components = {}
	for component in instanceTable.all do
		table.insert(components, component)
	end

	return components
end

local function start()
	CollectionService:GetInstanceRemovedSignal(MANAGED_TAG):Connect(clearInstance)
end

return {
	Kind = Kind,
	getKind = getKind,
	getAllComponents = getAllComponents,

	start = start,
}
