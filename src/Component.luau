local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local MANAGED_TAG = `_HC_MANAGED_{if RunService:IsServer() then "SV" else "CL"}`

local kinds = {}
local instanceTables = {}

local function clearInstance(instance)
	local instanceTable = instanceTables[instance]

	-- Explicitly deleting components could have cleaned this instance already
	if not instanceTable then return end
	
	for _, kindTable in instanceTable do
		for component, _ in kindTable do
			component:Destroy()
		end
	end
end

local function getOrCreateInstanceTable(instance: Instance)
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

local function getOrCreateKindTable(instanceTable, kindName: string)
	local kindTable = instanceTable.kinds[kindName]
	if kindTable then return kindTable end
	
	kindTable = {}
	instanceTable.kinds[kindName] = kindTable
	
	return kindTable
end

type Kind<T, V...> = {
	Name: string,

	Add: (instance: Instance, V...) -> Component<T, V...>,
	Get: (instance: Instance) -> Component<T, V...>?,
	Has: (instance: Instance) -> boolean,

	Destroy: (self: Kind<T, V...>) -> (),

	onAdd: (self: Kind<T, V...>, V...) -> (),
	onDestroy: (self: Kind<T, V...>) -> (),
} & T

type Component<T, V...> = Kind<T, V...> & {
	Instance: Instance
}

local function kind<T, V...>(name: string)
	assert(not kinds[name], `Component kind with name \"{name}\" already exists`)

	local kind = {
		Name = name,
	}
	kind.__index = kind

	function kind.Add(instance: Instance, ...: any)
		assert(instance:IsDescendantOf(game), `Can't add components to non-parented instance`)

		local instanceTable = getOrCreateInstanceTable(instance)
		local kindTable = getOrCreateKindTable(instanceTable, name)
	
		local component = setmetatable({Instance = instance}, kind)
	
		instanceTable.all[component] = true
		kindTable[component] = true
	
		component:onAdd(...)
	
		return component
	end

	function kind.Get(instance: Instance)
		local instanceTable = instanceTables[instance]
		local kindTable = if instanceTable then instanceTable.kinds[name] else nil
	
		return if kindTable then next(kindTable) else nil :: Component<T, V...>
	end

	function kind.Has(instance: Instance): boolean
		local instanceTable = instanceTables[instance]
		return if instanceTable then instanceTable.kinds[name] ~= nil else false
	end
	
	function kind:Destroy()
		self:onDestroy()
		
		local instanceTable = instanceTables[self.Instance]
		local kindTable = instanceTable.kinds[name]
		
		kindTable[self] = nil
		instanceTable.all[self] = nil
		
		if not next(kindTable) then
			instanceTable.kinds[name] = nil
		end
		
		-- We don't need to keep track of this instance when no components are attached
		if not next(instanceTable.kinds) then
			instanceTables[self.Instance] = nil
			CollectionService:RemoveTag(self.Instance, MANAGED_TAG)
		end

		-- So that if they erroneously try to use it later, it will error
		table.clear(self)
	end
	
	function kind:onAdd(...: V...) end
	function kind:onDestroy() end
	
	kinds[name] = kind
	
	return kind :: Kind<T, V...>
end

local function getKind(name: string): Kind<any>
	local kind = kinds[name]
	assert(kind, `Component kind \"{name}\" doesn't exist`)
	return kind
end

local function add(instance: Instance, kindName: string, ...): Component<any, ...any>
	return getKind(kindName).Add(instance, ...)
end

local function get(instance: Instance, kindName: string): Component<any, ...any>?
	return getKind(kindName).Get(instance)
end

local function has(instance: Instance, kindName: string): boolean
	return getKind(kindName).Has(instance)
end

local function all(instance: Instance, predicate: ((any) -> boolean)?): {Component<any>}
	local instanceTable = instanceTables[instance]
	if not instanceTable then return {} end

	local pred = predicate or function() return true end

	local components = {}
	for component in instanceTable.all do
		if pred(component) then
			table.insert(components, component)
		end
	end

	return components
end

CollectionService:GetInstanceRemovedSignal(MANAGED_TAG):Connect(clearInstance)

return {
	Kind = kind,
	
	Add = add,
	Get = get,
	Has = has,
	All = all,
}