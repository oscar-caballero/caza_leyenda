--!strict
--[[
	MaranaService — La Maraña del jugador (D-019). Todo en el servidor; nada en el perfil.

	  · Escribe OlvidoMeter (0..1) en el Character; 1 = Enredado
	  · Enredado: herramientas bloqueadas (gate de ToolService) y WalkSpeed 8 durante 5 s
	  · Rescate: un compañero 2 s a menos de 6 studs sin disparar
	  · Avisos: Player.Tangled y Player.Freed {reason = "time" | "rescue"}

	  MaranaService.setSafeResolver(fn)   ¿esta posición está junto a un farol encendido?
	  MaranaService.setCap(player, n?)    tope (66 en el tutorial); nil = sin tope
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Net = require(Shared:WaitForChild("Net"))
local MaranaConfig = require(Shared:WaitForChild("Config"):WaitForChild("Marana"))
local MaranaRules = require(script.Parent.MaranaRules)
local CreatureService = require(script.Parent.CreatureService)
local ToolService = require(script.Parent.ToolService)

local TICK = 0.1 -- s: 10 Hz basta para contactos de criaturas lentas
local A = Types.Attributes

type Entry = {
	state: MaranaRules.State,
	character: Model?,
	humanoid: Humanoid?,
	root: BasePart?,
	walkSpeed: number,
}

local MaranaService = {}

local entries: { [Player]: Entry } = {}
local lastFired: { [Player]: number } = {}
local safeResolver: ((pos: Vector3) -> boolean)? = nil

local function bindCharacter(player: Player, character: Model)
	local e = entries[player]
	if e == nil then
		return
	end
	-- Personaje nuevo (reaparición): la Maraña empieza de cero
	local cap = e.state.cap -- el tope (tutorial) se conserva
	e.state = MaranaRules.new(MaranaConfig, os.clock())
	e.state.cap = cap
	e.character = character
	e.humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	local root = character:WaitForChild("HumanoidRootPart", 10)
	e.root = if root and root:IsA("BasePart") then root else nil
	e.walkSpeed = if e.humanoid then e.humanoid.WalkSpeed else 16
	character:SetAttribute(A.OlvidoMeter, 0)
end

local function addPlayer(player: Player)
	entries[player] = {
		state = MaranaRules.new(MaranaConfig, os.clock()),
		character = nil,
		humanoid = nil,
		root = nil,
		walkSpeed = 16,
	}
	player.CharacterAdded:Connect(function(character)
		bindCharacter(player, character)
	end)
	if player.Character then
		task.spawn(bindCharacter, player, player.Character)
	end
end

local function setTangledLook(e: Entry, tangled: boolean)
	if e.humanoid then
		e.humanoid.WalkSpeed = if tangled then MaranaConfig.TANGLED_WALKSPEED else e.walkSpeed
	end
end

local function step(dt: number)
	local now = os.clock()
	local creatures = CreatureService.list()

	-- Posiciones de todos una sola vez
	local positions: { [Player]: Vector3 } = {}
	for player, e in entries do
		if e.root and e.root.Parent and e.humanoid and e.humanoid.Health > 0 then
			positions[player] = e.root.Position
		end
	end

	for player, e in entries do
		local pos: Vector3? = positions[player]
		local character = e.character
		if pos == nil or character == nil then
			continue
		end
		local s = e.state

		-- Contactos (distancias al cuadrado, sin raycast)
		for _, c in creatures do
			local contact = MaranaConfig.Contacts[c.id]
			if contact then
				local d = c.pos - pos
				if d.X * d.X + d.Y * d.Y + d.Z * d.Z <= contact.radius * contact.radius then
					MaranaRules.contact(MaranaConfig, s, c.model, contact, now)
				end
			end
		end

		-- Posibles rescatadores
		local rescuers = {}
		if MaranaRules.isTangled(s, now) then
			local r2 = MaranaConfig.RESCUE_RADIUS * MaranaConfig.RESCUE_RADIUS
			for other, otherPos in positions do
				if other ~= player and not MaranaRules.isTangled(entries[other].state, now) then
					local d = otherPos - pos
					rescuers[other] = {
						near = d.X * d.X + d.Y * d.Y + d.Z * d.Z <= r2,
						firedAt = lastFired[other] or -math.huge,
					}
				end
			end
		end

		local safe = safeResolver ~= nil and safeResolver(pos)
		local event = MaranaRules.tick(MaranaConfig, s, dt, now, safe, rescuers)

		if event == "tangled" then
			setTangledLook(e, true)
			Net.fire("Notice", player, { key = "Player.Tangled", args = {} })
		elseif event == "freedByTime" or event == "freedByRescue" then
			setTangledLook(e, false)
			Net.fire("Notice", player, {
				key = "Player.Freed",
				args = { reason = if event == "freedByRescue" then "rescue" else "time" },
			})
		end

		local value = math.floor(s.meter / MaranaConfig.MAX * 100 + 0.5) / 100
		if character:GetAttribute(A.OlvidoMeter) ~= value then
			character:SetAttribute(A.OlvidoMeter, value)
		end
	end
end

------------------------------------------------------------------------
-- API pública
------------------------------------------------------------------------

function MaranaService.start()
	ToolService.setUseGate(function(player)
		local e = entries[player]
		return e == nil or not MaranaRules.isTangled(e.state, os.clock())
	end)
	ToolService.onUse(function(player)
		lastFired[player] = os.clock()
	end)
	CreatureService.onResolved(function(_, helpers)
		local now = os.clock()
		for _, player in helpers do
			local e = entries[player]
			if e then
				MaranaRules.resolved(MaranaConfig, e.state, now)
			end
		end
	end)

	Players.PlayerAdded:Connect(addPlayer)
	for _, p in Players:GetPlayers() do
		addPlayer(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		entries[player] = nil
		lastFired[player] = nil
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= TICK then
			step(acc)
			acc = 0
		end
	end)
end

function MaranaService.setSafeResolver(fn: (pos: Vector3) -> boolean)
	safeResolver = fn
end

function MaranaService.setCap(player: Player, cap: number?)
	local e = entries[player]
	if e then
		e.state.cap = cap or MaranaConfig.MAX
		e.state.meter = math.min(e.state.meter, e.state.cap)
	end
end

return MaranaService
