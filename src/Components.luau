local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local MANAGED_TAG = `_HC_MANAGED_{if RunService:IsServer() then "SV" else "CL"}`

type Kind<T, K, V...> = {
	Name: string,

	Add: (instance: Instance & K, V...) -> Component<T, K, V...>,
	Get: (instance: Instance & K) -> Component<T, K, V...>?,
	Has: (instance: Instance & K) -> boolean,

	Destroy: (self: Component<T, K, V...>) -> (),

	onAdd: (self: Component<T, K, V...>, V...) -> (),
	onDestroy: (self: Component<T, K, V...>) -> (),
} & T

type Component<T, K, V...> = Kind<T, K, V...> & {
	Instance: Instance & K,
	IsDestroyed: boolean,
	IsManaged: boolean,
}

local kindCache: {[string]: Component<any, Instance>} = {}
local instanceTables = {}

local function clearInstance(instance)
	local instanceTable = instanceTables[instance]

	-- Explicitly deleting components could have cleaned this instance already
	if not instanceTable then return end
	
	for component in instanceTable.all do
		if not component.IsManaged then continue end
		component:Destroy()
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

local function getKind(name: string): Kind<any, Instance>
	local kind = kindCache[name]
	if kind then return kind end

	local function errNotCreated()
		error(`Kind {name} is cached but not defined.`)
	end

	kind = {
		Name = name,

		Add = errNotCreated,
		Get = errNotCreated,
		Has = errNotCreated,
	}

	kindCache[name] = kind
	return kind
end

local function newKind<T, K, V...>(name: string)
	assert(not kindCache[name], `Component kind with name \"{name}\" already exists`)

	local kind = getKind(name)

	function kind.Add(instance, ...)
		assert(instance:IsDescendantOf(game), `Can't add components to non-parented instance`)

		local instanceTable = getOrCreateInstanceTable(instance)
		local kindTable = getOrCreateKindTable(instanceTable, name)
	
		local component = setmetatable({
			Instance = instance, 
			IsDestroyed = false, 
			IsManaged = true
		}, kind)
	
		instanceTable.all[component] = true
		kindTable[component] = true
	
		component:onAdd(...)
	
		return component :: Component<T, K, V...>
	end

	function kind.Get(instance: Instance)
		local instanceTable = instanceTables[instance]
		local kindTable = if instanceTable then instanceTable.kinds[name] else nil
	
		return (if kindTable then next(kindTable) else nil) :: Component<T, K, V...>?
	end

	function kind.Has(instance: Instance): boolean
		local instanceTable = instanceTables[instance]
		return if instanceTable then instanceTable.kinds[name] ~= nil else false
	end
	
	function kind:Destroy()
		if self.IsDestroyed then return end
		self.IsDestroyed = false

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
			self.Instance:RemoveTag(MANAGED_TAG)
		end

		-- So that if they erroneously try to use it later, it will error
		table.clear(self)
		self.IsDestroyed = true
	end
	
	function kind:onAdd(...: V...) end
	function kind:onDestroy() end

	return kind :: Kind<T, K, V...>
end

local function getAllComponents<T>(instance: Instance & T): {Component<any, T>}
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
	NewKind = newKind,
	GetKind = getKind,

	GetAllComponents = getAllComponents,

	Start = start,
}