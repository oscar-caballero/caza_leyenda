--!strict
--[[
	QuestService — Tutorial y misiones (D-019). Los pasos avanzan SOLO con eventos del servidor:
	  reach      el servidor mide la distancia del personaje al NetId (5 Hz)
	  activate   ToolService.onActivate (también cuenta para compañeros cercanos en el mismo paso)
	  dissipate  CreatureService.onResolved (quienes aportaron ≥10 %)
	  puzzle     PuzzleService.onSolved (jugadores cerca del acertijo)

	Se guarda el paso actual en QuestProgress; los contadores dentro de un paso no se guardan
	(son estado del encuentro, D-009): al volver a entrar el paso empieza de cero.
	Al terminar: grantReward("quest:<id>") — idempotente — con XP, Semillas, Fragmentos y bestiario.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Net = require(Shared:WaitForChild("Net"))
local QuestRules = require(Shared:WaitForChild("QuestRules"))
local Quests = require(Shared:WaitForChild("Config"):WaitForChild("Quests"))
local DataService = require(script.Parent.DataService)
local ToolService = require(script.Parent.ToolService)
local CreatureService = require(script.Parent.CreatureService)
local PuzzleService = require(script.Parent.PuzzleService)
local MaranaService = require(script.Parent.MaranaService)
local WorldRegistry = require(script.Parent.WorldRegistry)
local CreatureRules = require(script.Parent.CreatureRules)

local REACH_TICK = 0.2
local COOP_RADIUS = 40 -- studs: un compañero cercano en el mismo paso también avanza

local QuestService = {}

local progress: { [Player]: QuestRules.Progress } = {}

local function notice(player: Player, key: string, args: { [string]: any })
	Net.fire("Notice", player, { key = key, args = args })
end

local function stepOf(p: QuestRules.Progress): QuestRules.Step?
	local def = Quests.Defs[p.quest]
	return def and def.steps[p.step]
end

local function rootPos(player: Player): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

-- Al entrar a un paso: aparece lo que ese paso necesita (polillas del tutorial, el Rumor...)
local function enterStep(player: Player, p: QuestRules.Progress)
	local step = stepOf(p)
	local def = Quests.Defs[p.quest]
	MaranaService.setCap(player, def and def.maranaCap or nil)
	if step == nil then
		return
	end
	notice(player, "Quest.Step", { quest = p.quest, step = p.step, count = 0, total = step.count or 1 })

	local spawn = step.spawn
	if spawn == nil then
		return
	end
	local anchors = if type(spawn.at) == "table" then spawn.at else { spawn.at }
	for _, anchorId in anchors do
		local pos = WorldRegistry.position(anchorId)
		if pos then
			if spawn.shared and CreatureService.aliveNear(spawn.creature, pos, 20) then
				continue -- ya hay uno para todos (p. ej. el Rumor del río)
			end
			for i = 1, spawn.count do
				local offset = Vector3.new(math.cos(i * 2.4) * 4, 0, math.sin(i * 2.4) * 4)
				CreatureService.spawn(spawn.creature, pos + offset, workspace, false)
			end
		end
	end
end

local function grantQuest(player: Player, questId: string)
	local def = Quests.Defs[questId]
	local r = def.rewards
	local before = DataService.read(player)
	DataService.grantReward(player, `quest:{questId}`, function(d)
		d.CompletedQuests[questId] = true
		d.QuestProgress[questId] = nil
		if def.setsTutorialDone then
			d.TutorialDone = true
		end
		if r then
			d.Experience += r.xp
			d.Level = CreatureRules.levelForXp(d.Experience, Types.Limits.MAX_LEVEL)
			d.Seeds += r.seeds
			for _, f in r.fragments or {} do
				d.Fragments[f] = true
			end
			for creature, layers in r.bestiary or {} do
				for _, layer in layers do
					d.Bestiary[creature] = d.Bestiary[creature] or { Layers = {} }
					d.Bestiary[creature].Layers[layer] = true
				end
			end
		end
		return true
	end)
	notice(player, "Quest.Completed", { quest = questId })
	if r then
		if r.seeds > 0 then
			notice(player, "Reward.Seeds", { amount = r.seeds })
		end
		if r.fragments and #r.fragments > 0 then
			notice(player, "Reward.Fragment", { count = #r.fragments })
		end
		local after = DataService.read(player)
		if before and after and after.Level > before.Level then
			notice(player, "Level.Up", { level = after.Level })
		end
	end
end

local function startNext(player: Player)
	local view = DataService.read(player)
	if view == nil then
		return
	end
	local questId = QuestRules.nextQuest(Quests.Order, view.CompletedQuests)
	if questId == nil then
		progress[player] = nil
		MaranaService.setCap(player, nil)
		return
	end
	local p = { quest = questId, step = view.QuestProgress[questId] or 1, count = 0, seen = {} }
	progress[player] = p
	enterStep(player, p)
end

local function handle(player: Player, ev: QuestRules.Event)
	local p = progress[player]
	if p == nil then
		return
	end
	local result = QuestRules.apply(Quests.Defs[p.quest].steps, p, ev)
	if result == "count" then
		local step = stepOf(p)
		notice(
			player,
			"Quest.Step",
			{ quest = p.quest, step = p.step, count = p.count, total = step and step.count or 1 }
		)
	elseif result == "step" then
		local questId, stepIndex = p.quest, p.step
		DataService.update(player, function(d)
			d.QuestProgress[questId] = stepIndex
			return true
		end)
		enterStep(player, p)
	elseif result == "completed" then
		grantQuest(player, p.quest)
		startNext(player)
	end
end

-- El mismo evento para el jugador y sus compañeros cercanos en el mismo paso (cooperativo)
local function handleWithGroup(player: Player, ev: QuestRules.Event)
	handle(player, ev)
	local pos = rootPos(player)
	if pos == nil then
		return
	end
	-- `handle` ya ignora el evento si no corresponde al paso del compañero
	for other in progress do
		if other ~= player then
			local otherPos = rootPos(other)
			if otherPos and (otherPos - pos).Magnitude <= COOP_RADIUS then
				handle(other, ev)
			end
		end
	end
end

function QuestService.start()
	ToolService.onActivate(function(player, _tool, target)
		local netId = target:GetAttribute(Types.Attributes.NetId)
		if type(netId) == "string" then
			handleWithGroup(player, { kind = "activate", target = netId, boosted = ToolService.isBoosted(player) })
		end
	end)

	CreatureService.onResolved(function(model, helpers)
		local id = model:GetAttribute(Types.Attributes.CreatureId)
		for _, player in helpers do
			handle(player, { kind = "dissipate", creature = id :: string })
		end
	end)

	PuzzleService.onSolved(function(puzzleId, players)
		for _, player in players do
			handle(player, { kind = "puzzle", puzzle = puzzleId })
		end
	end)

	local function onJoin(player: Player)
		if DataService.waitForProfile(player) then
			startNext(player)
		end
	end
	Players.PlayerAdded:Connect(onJoin)
	for _, p in Players:GetPlayers() do
		task.spawn(onJoin, p)
	end
	Players.PlayerRemoving:Connect(function(player)
		progress[player] = nil
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < REACH_TICK then
			return
		end
		acc = 0
		for player, p in progress do
			local step = stepOf(p)
			if step and step.kind == "reach" and step.target then
				local target = WorldRegistry.position(step.target)
				local pos = rootPos(player)
				if target and pos and (pos - target).Magnitude <= (step.radius or 8) then
					handle(player, { kind = "reach", target = step.target })
				end
			end
		end
	end)
end

return QuestService
