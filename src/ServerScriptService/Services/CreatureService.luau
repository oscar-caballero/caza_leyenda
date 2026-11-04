--!strict
--[[
	CreatureService — Criaturas del Olvido (nivel 3) del lado del servidor.

	  CreatureService.register(model)   empieza a manejar un Model con atributos CreatureId y NetId

	Cada criatura registrada:
	  · OlvidoMeter (0..1) y EncounterState ("Idle" | "Active" | "Resolved") como atributos replicados
	  · se mueve en el servidor (deambula, se acerca, huye tras un golpe; el yo-yo la frena)
	  · escala con el grupo cercano al activarse (D-008: n≤4 → ×2.5)
	  · al disiparse: recompensa a quien ayudó (≥10 % del daño) y reaparece tras `respawn`
	  · guarda 0.5 s de posiciones para el rebobinado de ToolService (D-009, máx. 250 ms)

	Las de nivel 1 y 2 no se registran aquí: se resuelven con acertijos (QuestService).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Net = require(Shared:WaitForChild("Net"))
local CreaturesConfig = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local ToolsConfig = require(Shared.Config:WaitForChild("Tools"))
local CreatureRules = require(script.Parent.CreatureRules)
local DataService = require(script.Parent.DataService)
local AssetLibrary = require(script.Parent.AssetLibrary)
local ToolService = require(script.Parent.ToolService)

local A = Types.Attributes
local MAX_REWIND = 0.25 -- s (D-009)
local HISTORY_KEEP = 0.5 -- s
local COOP_RADIUS = 60 -- studs: quién cuenta como "grupo cercano"
local MIN_SHARE = 0.10 -- aporte mínimo para recibir recompensa
local WANDER_EVERY = 3 -- s
local WANDER_RADIUS = 8 -- studs

type Creature = {
	model: Model,
	id: string,
	netId: string,
	cfg: CreaturesConfig.CreatureDef,
	home: Vector3,
	pos: Vector3,
	meter: number,
	scale: number,
	state: string,
	contributions: { [Player]: number },
	fleeUntil: number,
	slowUntil: number,
	slowMult: number,
	wanderTarget: Vector3,
	nextWander: number,
	history: { CreatureRules.Sample },
	saved: { [BasePart]: number }, -- transparencias originales mientras está disipada
	respawn: boolean, -- false: al disiparse desaparece (criaturas de misión o de acertijo)
	wings: { Wing }?, -- alas que aletean (modelo real de la polilla)
}

type Wing = {
	part: BasePart,
	rel: CFrame, -- posición del ala respecto al cuerpo, en reposo
	hinge: Vector3, -- bisagra (borde interior del ala) en el espacio del cuerpo
	side: number, -- -1 o 1
}

local FLAP_SPEED = 14 -- rad/s
local FLAP_ANGLE = 0.55 -- rad

local CreatureService = {}

local creatures: { [Model]: Creature } = {}

export type CreatureInfo = { model: Model, id: string, pos: Vector3 }
local resolvedListeners: { (model: Model, helpers: { Player }) -> () } = {}

local function setState(c: Creature, state: string)
	c.state = state
	c.model:SetAttribute(A.EncounterState, state)
end

local function setMeter(c: Creature, meter: number)
	c.meter = meter
	c.model:SetAttribute(A.OlvidoMeter, meter)
end

local function playerRoots(): { { player: Player, pos: Vector3 } }
	local out = {}
	for _, p in Players:GetPlayers() do
		local character = p.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
			table.insert(out, { player = p, pos = root.Position })
		end
	end
	return out
end

local function setVisible(c: Creature, visible: boolean)
	for _, d in c.model:GetDescendants() do
		if d:IsA("BasePart") then
			if visible then
				d.Transparency = c.saved[d] or d.Transparency
				d.CanQuery = true
			else
				c.saved[d] = d.Transparency
				d.Transparency = 1
				d.CanQuery = false
			end
		end
	end
end

------------------------------------------------------------------------
-- Recompensas (ECONOMÍA: valores propuestos en Config/Creatures, D-010)
------------------------------------------------------------------------

local function reward(c: Creature)
	local rewards = c.cfg.rewards
	if rewards == nil then
		return
	end
	for _, player in CreatureRules.eligible(c.contributions, MIN_SHARE) do
		if player.Parent ~= Players then
			continue
		end
		local before = DataService.read(player)
		DataService.update(player, function(d)
			d.Experience += rewards.xp
			d.Level = CreatureRules.levelForXp(d.Experience, Types.Limits.MAX_LEVEL)
			return true
		end)
		local after = DataService.read(player)
		if before and after and after.Level > before.Level then
			Net.fire("Notice", player, { key = "Level.Up", args = { level = after.Level } })
		end

		if rewards.firstSeeds > 0 then
			local ok = DataService.grantReward(player, `defeat:{c.netId}`, function(d)
				d.Seeds += rewards.firstSeeds
				return true
			end)
			if ok then
				Net.fire("Notice", player, { key = "Reward.Seeds", args = { amount = rewards.firstSeeds } })
			end
		end
	end
end

------------------------------------------------------------------------
-- Golpes (desde ToolService)
------------------------------------------------------------------------

local function onHit(player: Player, tool: string, model: Model, damage: number)
	local c = creatures[model]
	if c == nil or c.state == "Resolved" then
		return
	end
	if c.state == "Idle" then
		setState(c, "Active")
	end

	c.contributions[player] = (c.contributions[player] or 0) + damage
	setMeter(c, CreatureRules.applyDamage(c.meter, damage, c.cfg.maxOlvido :: number, c.scale))

	local now = os.clock()
	local fleeSeconds = c.cfg.fleeSeconds or 0
	if fleeSeconds > 0 then
		c.fleeUntil = now + fleeSeconds
	end
	local slow = ToolsConfig.Defs[tool] and ToolsConfig.Defs[tool].slow
	if slow then
		c.slowUntil = now + slow.seconds
		c.slowMult = slow.mult
	end

	if c.meter <= 0 then
		setState(c, "Resolved")
		setVisible(c, false)
		reward(c)
		local helpers = CreatureRules.eligible(c.contributions, MIN_SHARE)
		for _, fn in resolvedListeners do
			task.spawn(fn, model, helpers)
		end
		if not c.respawn then
			task.delay(1.5, function()
				creatures[model] = nil
				model:Destroy()
			end)
			return
		end
		task.delay(c.cfg.respawn or 10, function()
			if creatures[model] ~= c then
				return
			end
			c.pos = c.home
			c.model:PivotTo(CFrame.new(c.home))
			c.contributions = {}
			c.scale = 1
			c.fleeUntil, c.slowUntil = 0, 0
			table.clear(c.history)
			setMeter(c, 1)
			setVisible(c, true)
			setState(c, "Idle")
		end)
	end
end

------------------------------------------------------------------------
-- Rebobinado: ¿el rayo habría tocado a alguna criatura en el instante t?
------------------------------------------------------------------------

local function rewindResolver(origin: Vector3, aim: Vector3, range: number, radius: number, clientTime: number): Model?
	local t = CreatureRules.rewindTime(clientTime, workspace:GetServerTimeNow(), MAX_REWIND)
	local best: Creature? = nil
	local bestDist = math.huge
	for _, c in creatures do
		if c.state ~= "Resolved" then
			local pos = CreatureRules.positionAt(c.history, t)
			if pos then
				local dist = CreatureRules.raySphere(origin, aim, range, pos, (c.cfg.hitRadius or 2) + radius)
				if dist and dist < bestDist then
					best, bestDist = c, dist
				end
			end
		end
	end
	if best == nil then
		return nil
	end

	-- Sin atravesar paredes: línea de vista contra el escenario (sin personajes ni criaturas)
	local exclude: { Instance } = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(exclude, p.Character)
		end
	end
	for m in creatures do
		table.insert(exclude, m)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude
	local blocked = workspace:Raycast(origin, aim * bestDist, params)
	if blocked then
		return nil
	end
	return best.model
end

------------------------------------------------------------------------
-- Movimiento
------------------------------------------------------------------------

local function nearest(c: Creature, roots: { { player: Player, pos: Vector3 } }): (Vector3?, number)
	local best: Vector3? = nil
	local bestDist = c.cfg.aggroRadius or 30
	for _, r in roots do
		local d = (r.pos - c.pos).Magnitude
		if d <= bestDist then
			best, bestDist = r.pos, d
		end
	end
	return best, bestDist
end

local function countNearby(c: Creature, roots: { { player: Player, pos: Vector3 } }): number
	local n = 0
	for _, r in roots do
		if (r.pos - c.pos).Magnitude <= COOP_RADIUS then
			n += 1
		end
	end
	return n
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function step(c: Creature, dt: number, now: number, serverNow: number, roots)
	local cfg = c.cfg
	local target, _ = nearest(c, roots)

	-- Estado del encuentro y escalado cooperativo (solo sube mientras dura el encuentro)
	if target and c.state == "Idle" then
		setState(c, "Active")
	elseif target == nil and c.state == "Active" and c.meter >= 1 then
		setState(c, "Idle")
	end
	if c.state == "Active" then
		c.scale = math.max(c.scale, CreatureRules.coopScale(countNearby(c, roots)))
	end

	local speed = cfg.speed or 6
	local goal: Vector3
	if target and now < c.fleeUntil then
		local away = flat(c.pos - target)
		goal = c.pos + (if away.Magnitude > 0.01 then away.Unit else Vector3.xAxis) * 10
		speed = cfg.fleeSpeed or speed
	elseif target then
		local toward = flat(target - c.pos)
		local keep = cfg.keepDistance or 6
		goal = if toward.Magnitude > keep then target - toward.Unit * keep else c.pos
	else
		if now >= c.nextWander then
			local angle = math.random() * math.pi * 2
			c.wanderTarget = c.home + Vector3.new(math.cos(angle), 0, math.sin(angle)) * math.random() * WANDER_RADIUS
			c.nextWander = now + WANDER_EVERY
		end
		goal = c.wanderTarget
	end
	if now < c.slowUntil then
		speed *= c.slowMult
	end

	-- Correa: nunca se aleja más de leashRadius de su origen
	local leash = cfg.leashRadius or 25
	local fromHome = flat(goal - c.home)
	if fromHome.Magnitude > leash then
		goal = c.home + fromHome.Unit * leash
	end

	local delta = flat(goal - c.pos)
	local dist = delta.Magnitude
	local facing = if dist > 0.01 then delta.Unit else nil
	if dist > 0.01 then
		c.pos += delta.Unit * math.min(speed * dt, dist)
	end

	local bob = if c.id == "PolillaPapel" then math.sin(now * 3 + c.home.X) * 0.6 else 0
	local drawPos = Vector3.new(c.pos.X, c.home.Y + bob, c.pos.Z)
	if facing then
		c.model:PivotTo(CFrame.lookAt(drawPos, drawPos + facing))
	else
		c.model:PivotTo(CFrame.new(drawPos) * c.model:GetPivot().Rotation)
	end

	if c.wings and c.model.PrimaryPart then
		local body = c.model.PrimaryPart.CFrame
		local a = math.sin(now * FLAP_SPEED + c.home.X) * FLAP_ANGLE
		for _, w in c.wings do
			w.part.CFrame = body * CFrame.new(w.hinge) * CFrame.Angles(0, 0, w.side * a) * CFrame.new(-w.hinge) * w.rel
		end
	end

	table.insert(c.history, { t = serverNow, pos = drawPos })
	CreatureRules.trimHistory(c.history, serverNow, HISTORY_KEEP)
end

------------------------------------------------------------------------
-- API pública
------------------------------------------------------------------------

function CreatureService.register(model: Model, respawn: boolean?)
	local id = model:GetAttribute(A.CreatureId)
	local netId = model:GetAttribute(A.NetId)
	assert(
		type(id) == "string" and type(netId) == "string",
		`CreatureService: {model:GetFullName()} sin CreatureId/NetId`
	)
	local cfg = CreaturesConfig[id]
	assert(cfg and cfg.level == 3, `CreatureService: '{id}' no es criatura de nivel 3`)

	local home = model:GetPivot().Position
	local c: Creature = {
		model = model,
		id = id,
		netId = netId,
		cfg = cfg,
		home = home,
		pos = home,
		meter = 1,
		scale = 1,
		state = "Idle",
		contributions = {},
		fleeUntil = 0,
		slowUntil = 0,
		slowMult = 1,
		wanderTarget = home,
		nextWander = 0,
		history = {},
		saved = {},
		respawn = respawn ~= false,
		wings = nil,
	}
	local body = model.PrimaryPart
	local left, right = model:FindFirstChild("AlaIzq"), model:FindFirstChild("AlaDer")
	if body and left and right and left:IsA("BasePart") and right:IsA("BasePart") then
		local wings = {}
		for _, w in { left, right } do
			local rel = body.CFrame:ToObjectSpace(w.CFrame)
			local side = if rel.Position.X >= 0 then 1 else -1
			-- bisagra: el borde del ala más cercano al cuerpo
			local hinge = Vector3.new(rel.Position.X - side * w.Size.X / 2, rel.Position.Y, rel.Position.Z)
			table.insert(wings, { part = w, rel = rel, hinge = hinge, side = side })
		end
		c.wings = wings
	end
	creatures[model] = c
	setMeter(c, 1)
	setState(c, "Idle")

	model.Destroying:Connect(function()
		creatures[model] = nil
	end)
end

-- Tamaño provisional (blockout) hasta que llegue el arte del Artista 3D
local PLACEHOLDER = {
	PolillaPapel = { size = 2, color = Color3.fromRGB(245, 240, 225) },
	Rumor = { size = 8, color = Color3.fromRGB(150, 150, 160) },
}
local spawnCounter = 0

--[[
	Crea una criatura de nivel 3 en `pos` (misiones y acertijos).
	respawn = false: desaparece al disiparse.
]]
function CreatureService.spawn(id: string, pos: Vector3, parent: Instance, respawn: boolean?): Model
	spawnCounter += 1
	local model: Model
	local asset = AssetLibrary.clone(id, false)
	if asset then
		model = asset
		-- Modelo real (assets/roblox): la pieza principal es "Cuerpo" o la única que tenga
		local main = model:FindFirstChild("Cuerpo")
			or model:FindFirstChild(id)
			or model:FindFirstChildWhichIsA("BasePart")
		model.PrimaryPart = main :: BasePart
		model:PivotTo(CFrame.new(pos))
	else
		local look = PLACEHOLDER[id] or { size = 3, color = Color3.new(1, 1, 1) }
		model = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Anchored = true
		body.Size = Vector3.one * look.size
		body.Color = look.color
		body.Position = pos
		body.Parent = model
		model.PrimaryPart = body
	end
	model.Name = id
	model:SetAttribute(A.CreatureId, id)
	model:SetAttribute(A.NetId, `spawn_{id}_{spawnCounter}`)
	model.Parent = parent
	CreatureService.register(model, respawn)
	return model
end

-- ¿Hay una criatura viva de este tipo cerca de pos? (para no duplicar criaturas compartidas)
function CreatureService.aliveNear(id: string, pos: Vector3, radius: number): boolean
	for _, c in creatures do
		if c.id == id and c.state ~= "Resolved" and (c.home - pos).Magnitude <= radius then
			return true
		end
	end
	return false
end

-- Criaturas activas (no disipadas) con su posición actual: la usa MaranaService
function CreatureService.list(): { CreatureInfo }
	local out = {}
	for model, c in creatures do
		if c.state ~= "Resolved" then
			table.insert(out, { model = model, id = c.id, pos = c.pos })
		end
	end
	return out
end

-- Una criatura se disipó; `helpers` son quienes aportaron ≥10 % del daño
function CreatureService.onResolved(fn: (model: Model, helpers: { Player }) -> ())
	table.insert(resolvedListeners, fn)
end

function CreatureService.start()
	ToolService.onHit(onHit)
	ToolService.setRewindResolver(rewindResolver)

	Players.PlayerRemoving:Connect(function(player)
		for _, c in creatures do
			c.contributions[player] = nil
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		local serverNow = workspace:GetServerTimeNow()
		local roots = playerRoots()
		for _, c in creatures do
			if c.state ~= "Resolved" then
				step(c, dt, now, serverNow, roots)
			end
		end
	end)
end

return CreatureService
