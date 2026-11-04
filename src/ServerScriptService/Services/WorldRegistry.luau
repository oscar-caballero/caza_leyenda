--!strict
--[[
	WorldRegistry — NetId → instancia del mundo (solo servidor).
	Lo usan Net (validar distancia), QuestService (pasos "reach") y PuzzleService.
]]

local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Types"))

local WorldRegistry = {}

local byId: { [string]: Instance } = {}

function WorldRegistry.register(netId: string, inst: Instance)
	local existing: Instance? = byId[netId]
	assert(existing == nil or existing == inst, `WorldRegistry: NetId repetido '{netId}'`)
	byId[netId] = inst
	inst:SetAttribute(Types.Attributes.NetId, netId)
	inst.Destroying:Connect(function()
		local current: Instance? = byId[netId]
		if current == inst then
			byId[netId] = nil
		end
	end)
end

function WorldRegistry.get(netId: string): Instance?
	return byId[netId]
end

function WorldRegistry.position(netId: string): Vector3?
	local inst: Instance? = byId[netId]
	if inst == nil then
		return nil
	end
	if inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	return nil
end

return WorldRegistry
