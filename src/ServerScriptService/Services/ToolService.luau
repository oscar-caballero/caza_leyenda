--!strict
--[[
	ToolService — Herramientas del lado del servidor (D-004, D-007, D-009).

	Remotes que atiende: ToolUse, ToolEquip, ToolUpgrade.
	El servidor decide todo: si la herramienta está equipada, cooldown, resortera,
	impacto (spherecast propio desde la cabeza del personaje) y daño.

	Otros servicios se suscriben a lo que pasa:
	  ToolService.onHit(fn)       golpe a una criatura de nivel 3 → CreatureService baja el medidor
	  ToolService.onActivate(fn)  herramienta activó un objeto con su tag → QuestService

	PENDIENTE (CreatureBase): rebobinado de hasta 250 ms (D-009). Requiere historial de
	posiciones de las criaturas; hoy `clientTime` se valida pero no se usa.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Net = require(Shared:WaitForChild("Net"))
local ToolsConfig = require(Shared:WaitForChild("Config"):WaitForChild("Tools"))
local CreaturesConfig = require(Shared.Config:WaitForChild("Creatures"))
local DataService = require(script.Parent.DataService)
local ToolRules = require(script.Parent.ToolRules)

export type HitListener = (player: Player, tool: string, creature: Model, damage: number) -> ()
export type ActivateListener = (player: Player, tool: string, target: Instance) -> ()

type PlayerState = {
	lastUse: { [string]: number },
	boostedUntil: number,
}

local FX_RADIUS = 200 -- studs: a quién se le pinta el disparo de otro jugador

local ToolService = {}

local states: { [Player]: PlayerState } = {}
local hitListeners: { HitListener } = {}
local activateListeners: { ActivateListener } = {}

local function getState(player: Player): PlayerState
	local s = states[player]
	if s == nil then
		s = { lastUse = {}, boostedUntil = 0 }
		states[player] = s
	end
	return s
end

local function notice(player: Player, key: string, args: { [string]: any }?)
	Net.fire("Notice", player, { key = key, args = args or {} })
end

local function rootPart(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function isInTown(player: Player): boolean
	local root = rootPart(player)
	if root == nil then
		return false
	end
	for _, zone in CollectionService:GetTagged(Types.Tags.ZonaPueblo) do
		if zone:IsA("BasePart") then
			local p = zone.CFrame:PointToObjectSpace(root.Position)
			local half = zone.Size / 2
			if math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z then
				return true
			end
		end
	end
	return false
end

-- Sube desde la parte golpeada hasta encontrar el modelo con atributo CreatureId
local function findCreature(hit: Instance): (Model?, string?)
	local node: Instance? = hit
	while node and node ~= workspace do
		local id = node:GetAttribute(Types.Attributes.CreatureId)
		if type(id) == "string" and node:IsA("Model") then
			return node, id
		end
		node = node.Parent
	end
	return nil, nil
end

local function findTagged(hit: Instance, tag: string): Instance?
	local node: Instance? = hit
	while node and node ~= workspace do
		if CollectionService:HasTag(node, tag) then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function emit<T...>(listeners: { (T...) -> () }, ...: T...)
	for _, fn in listeners do
		task.spawn(fn, ...)
	end
end

------------------------------------------------------------------------
-- Handlers de Remotes
------------------------------------------------------------------------

local function onToolUse(player: Player, payload: Net.Payload)
	local tool: string = payload.tool
	local def = ToolsConfig.Defs[tool]
	local view = DataService.read(player)
	if view == nil or not def.enabled or not ToolRules.isEquipped(view.Equipped, tool) then
		return
	end

	local state = getState(player)
	local now = os.clock()
	local boosted = tool == "Honda" and state.boostedUntil > now
	if now - (state.lastUse[tool] or -math.huge) < ToolRules.cooldown(def, boosted, ToolsConfig.Resortera) then
		return -- cooldown: se ignora en silencio (el cliente ya lo limita)
	end
	state.lastUse[tool] = now

	local root = rootPart(player)
	if root == nil then
		return
	end
	local character = player.Character :: Model
	local head = character:FindFirstChild("Head")
	local origin = if head and head:IsA("BasePart") then head.Position else root.Position + Vector3.new(0, 1.5, 0)
	local aim: Vector3 = payload.aim

	-- El impacto lo calcula el servidor; hitHint del cliente no se usa para decidir
	local exclude = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(exclude, p.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude
	local result = workspace:Spherecast(origin, def.radius, aim * def.range, params)

	if result then
		local creature, creatureId = findCreature(result.Instance)
		if creature and creatureId then
			local cfg = CreaturesConfig[creatureId]
			if ToolRules.canDamage(cfg) then
				local tier = view.ToolTiers[tool] or 0
				local dmg = ToolRules.damage(ToolsConfig, tool, tier, boosted, cfg)
				emit(hitListeners, player, tool, creature, dmg)
			end
		end
		local target = findTagged(result.Instance, def.activatesTag)
		if target then
			emit(activateListeners, player, tool, target)
		end
	end

	-- Efecto visual para los demás jugadores cercanos (el que dispara ya lo pintó)
	local others = {}
	for _, p in Players:GetPlayers() do
		local r = rootPart(p)
		if p ~= player and r and (r.Position - origin).Magnitude <= FX_RADIUS then
			table.insert(others, p)
		end
	end
	if #others > 0 then
		Net.fireList("ToolFx", others, {
			userId = player.UserId,
			tool = tool,
			origin = origin,
			aim = aim,
			boosted = boosted,
		})
	end
end

local function onToolEquip(player: Player, payload: Net.Payload)
	local tool: string = payload.tool
	local slot: number = payload.slot
	if not ToolsConfig.Defs[tool].enabled or not DataService.isLoaded(player) then
		return
	end
	if not isInTown(player) then
		notice(player, "Tool.EquipOnlyInTown")
		return
	end
	DataService.update(player, function(d)
		d.Equipped = ToolRules.equip(d.Equipped, slot, tool)
		return true
	end)
end

local function onToolUpgrade(player: Player, payload: Net.Payload)
	local tool: string = payload.tool
	local view = DataService.read(player)
	if view == nil or not ToolsConfig.Defs[tool].enabled then
		return
	end
	local tier: number = view.ToolTiers[tool] or 0
	local cost = ToolRules.upgradeCost(ToolsConfig.UpgradeCosts, tier)
	if cost == nil then
		return -- ya está al máximo
	end
	local ok, err = DataService.spendSeeds(player, cost, function(d)
		if d.ToolTiers[tool] ~= tier then
			return false -- cambió mientras tanto: no cobrar
		end
		d.ToolTiers[tool] = tier + 1
		return true
	end)
	if ok then
		notice(player, "Tool.Upgraded", { tool = tool, tier = tier + 1 })
	elseif err == "seeds.insufficient" then
		notice(player, "Tool.NotEnoughSeeds", { tool = tool, cost = cost })
	end
end

------------------------------------------------------------------------
-- Resortera (power-up momentáneo, D-013): se recoge tocándola
------------------------------------------------------------------------

local function setupResortera(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local available = true
	part.Touched:Connect(function(hit)
		if not available then
			return
		end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player == nil then
			return
		end
		available = false
		getState(player).boostedUntil = os.clock() + ToolsConfig.Resortera.duration
		local transparency = part.Transparency
		part.Transparency = 1
		task.delay(ToolsConfig.Resortera.respawn, function()
			part.Transparency = transparency
			available = true
		end)
	end)
end

------------------------------------------------------------------------
-- API pública
------------------------------------------------------------------------

function ToolService.start()
	Net.on("ToolUse", onToolUse)
	Net.on("ToolEquip", onToolEquip)
	Net.on("ToolUpgrade", onToolUpgrade)

	for _, part in CollectionService:GetTagged(Types.Tags.PowerUpResortera) do
		setupResortera(part)
	end
	CollectionService:GetInstanceAddedSignal(Types.Tags.PowerUpResortera):Connect(setupResortera)

	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

function ToolService.onHit(fn: HitListener)
	table.insert(hitListeners, fn)
end

function ToolService.onActivate(fn: ActivateListener)
	table.insert(activateListeners, fn)
end

-- Para el HUD/servicios: ¿tiene la resortera activa?
function ToolService.isBoosted(player: Player): boolean
	local s = states[player]
	return s ~= nil and s.boostedUntil > os.clock()
end

return ToolService
