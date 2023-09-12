local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Types = require(script.Parent.Types)

local MANAGED_TAG = `_HC_MANAGED_{if RunService:IsServer() then "SV" else "CL"}`

local kindCache = {}
local instanceTables = {}

local function clearInstance(instance)
	local instanceTable = instanceTables[instance]

	-- Explicitly deleting components could have cleaned this instance already
	if not instanceTable then
		return
	end

	for component in instanceTable.all do
		if component.unmanaged then
			continue
		end
		component:Destroy()
	end
end

local function getOrCreateInstanceTable(instance: Instance)
	local instanceTable = instanceTables[instance]
	if instanceTable then
		return instanceTable
	end

	instanceTable = {
		kinds = {},
		all = {},
	}
	instanceTables[instance] = instanceTable

	CollectionService:AddTag(instance, MANAGED_TAG)

	return instanceTable
end

local function getOrCreateKindTable(instanceTable, kindName: string)
	local kindTable = instanceTable.kinds[kindName]
	if kindTable then
		return kindTable
	end

	kindTable = {}
	instanceTable.kinds[kindName] = kindTable

	return kindTable
end

local function Kind<TInstance, TComponent, TArgs...>(
	name: string,
	initializer: (TComponent, TArgs...) -> TComponent
): Types.Kind<TInstance, TComponent, TArgs...>
	local this = {}

	return this :: any
end

local function getKind(name: string): Types.Kind<Instance, Types.Component<Instance>, any>
	local kind = kinds[name]
	assert(kind, `Kind "{name}" doesn't exist!`)

	return kind
end

local function getAllComponents<T>(instance: Instance & T): { Types.Component<T> }
	local instanceTable = instanceTables[instance]
	if not instanceTable then
		return {}
	end

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
