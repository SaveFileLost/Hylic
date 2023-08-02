local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local MANAGED_TAG = `_HC_MANAGED_{if RunService:IsServer() then "SV" else "CL"}`

local kinds = {}
local instanceTables = {}

local function clearInstance(instance)
	local instanceTable = instanceTables[instance]
	assert(instanceTable, "Instance tagged as managed isn't actually managed. How did this happen?")
	
	for _, kindTable in instanceTable do
		for component, _ in kindTable do
			component:delete()
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

local function Component(name: string)
	assert(not kinds[name], `Component kind with name \"{name}\" already exists`)

	local kind = {}
	kind.__index = kind
	
	function kind:delete()
		self:onDelete()
		
		local instanceTable = instanceTables[self.instance]
		local kindTable = instanceTable.kinds[name]
		
		kindTable[self] = nil
		instanceTable.all[self] = nil
		
		if not next(kindTable) then
			instanceTable.kinds[name] = nil
		end
		
		-- We don't need to keep track of this instance when no components are attached
		if not next(instanceTable.kinds) then
			instanceTables[self.instance] = nil
		end
	end
	
	function kind:onAdd() end
	function kind:onDelete() end
	
	kinds[name] = kind
	
	return kind
end

local function add(instance: Instance, kindName: string, ...)
	assert(instance:IsDescendantOf(game), `Can't add components to non-parented instance`)
	
	local kind = kinds[kindName]
	assert(kind, `Component kind \"{kindName}\" doesn't exist`)
	
	local instanceTable = getOrCreateInstanceTable(instance)
	local kindTable = getOrCreateKindTable(instanceTable, kindName)
	
	local component = {instance = instance}
	setmetatable(component, kind)
	
	instanceTable.all[component] = true
	kindTable[component] = true
	
	component:onAdd(...)
	
	return component
end

local function get(instance: Instance, kindName: string)
	local instanceTable = instanceTables[instance]
	local kindTable = if instanceTable then instanceTable.kinds[kindName] else nil
	
	return if kindTable then next(kindTable) else nil
end

local function has(instance: Instance, kindName: string): boolean
	local instanceTable = instanceTables[instance]
	return if instanceTable then instanceTable.kinds[kindName] ~= nil else false
end

local function all(instance: Instance, predicate: ((any) -> boolean)?): {any}
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
	Component = Component,
	
	add = add,
	get = get,
	has = has,
	all = all,
}