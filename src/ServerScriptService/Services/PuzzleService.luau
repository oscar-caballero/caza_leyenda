--!strict
--[[
	PuzzleService — Acertijos físicos (Config/Puzzles). Se resuelven ACTIVANDO objetos con
	las herramientas (ToolService.onActivate); el servidor lleva el estado.

	Fallar (D-005, biblia §5): la pista desaparece porque "las polillas se la comieron";
	aparecen polillas junto al acertijo y, al disiparlas todas, la pista vuelve.

	El estado es del servidor (compartido por quienes estén cerca), no del perfil. Al resolverse
	avisa a todos los jugadores cercanos y se reinicia a los 3 s para quien llegue después.

	  PuzzleService.onSolved(fn(puzzleId, players))
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Net = require(Shared:WaitForChild("Net"))
local Puzzles = require(Shared:WaitForChild("Config"):WaitForChild("Puzzles"))
local ToolService = require(script.Parent.ToolService)
local CreatureService = require(script.Parent.CreatureService)
local WorldRegistry = require(script.Parent.WorldRegistry)

local NEAR = 40 -- studs: quién participa del acertijo
local RESET_AFTER = 3 -- s

type State = {
	index: number, -- siguiente objetivo esperado (sequence)
	hits: { [string]: number }, -- objetivo → instante (together)
	locked: boolean, -- pista comida: hay que disipar polillas
	pending: number, -- polillas de castigo vivas
	solvedAt: number?,
}

local PuzzleService = {}

local states: { [string]: State } = {}
local byTarget: { [string]: string } = {} -- NetId de objetivo → id del acertijo
local solvedListeners: { (puzzleId: string, players: { Player }) -> () } = {}

local function nearby(puzzleId: string): { Player }
	local out = {}
	local anchor = WorldRegistry.position(Puzzles[puzzleId].anchor)
	if anchor == nil then
		return out
	end
	for _, p in Players:GetPlayers() do
		local character = p.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and (root.Position - anchor).Magnitude <= NEAR then
			table.insert(out, p)
		end
	end
	return out
end

local function notify(puzzleId: string, key: string, result: string, step: number)
	local players = nearby(puzzleId)
	if #players == 0 then
		return players
	end
	Net.fireList("Notice", players, { key = key, args = { puzzle = puzzleId } })
	Net.fireList("PuzzleResult", players, { puzzle = puzzleId, step = math.clamp(step, 1, 16), result = result })
	return players
end

local function setClueVisible(puzzleId: string, visible: boolean)
	local clueId = Puzzles[puzzleId].clue
	local clue = clueId and WorldRegistry.get(clueId)
	if clue == nil then
		return
	end
	for _, d in clue:GetDescendants() do
		if d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
			(d :: any).Enabled = visible
		end
	end
	if clue:IsA("BasePart") then
		clue.Transparency = if visible then 0 else 0.8
	end
end

local function fail(puzzleId: string, s: State)
	local cfg = Puzzles[puzzleId]
	s.index = 1
	table.clear(s.hits)
	notify(puzzleId, "Puzzle.Failed", "Failed", 1)

	local spawn = cfg.failSpawn
	local anchor = WorldRegistry.position(cfg.anchor)
	if spawn == nil or anchor == nil then
		return
	end
	s.locked = true
	setClueVisible(puzzleId, false)
	for i = 1, spawn.count do
		local offset = Vector3.new(math.cos(i * 2.1) * 5, 3, math.sin(i * 2.1) * 5)
		local model = CreatureService.spawn(spawn.creature, anchor + offset, workspace, false)
		s.pending += 1
		model.Destroying:Connect(function()
			s.pending -= 1
			if s.pending <= 0 then
				s.pending = 0
				s.locked = false
				setClueVisible(puzzleId, true) -- la pista vuelve
			end
		end)
	end
end

local function solve(puzzleId: string, s: State)
	s.solvedAt = os.clock()
	local players = notify(puzzleId, "Puzzle.Solved", "Solved", #Puzzles[puzzleId].targets)
	for _, fn in solvedListeners do
		task.spawn(fn, puzzleId, players)
	end
	task.delay(RESET_AFTER, function()
		s.index = 1
		table.clear(s.hits)
		s.solvedAt = nil
	end)
end

local function onActivate(_player: Player, _tool: string, target: Instance)
	local netId = target:GetAttribute(Types.Attributes.NetId)
	if type(netId) ~= "string" then
		return
	end
	local puzzleId = byTarget[netId]
	if puzzleId == nil then
		return
	end
	local cfg = Puzzles[puzzleId]
	local s = states[puzzleId]
	if s.locked or s.solvedAt then
		return
	end

	if cfg.kind == "sequence" then
		if cfg.targets[s.index] == netId then
			s.index += 1
			if s.index > #cfg.targets then
				solve(puzzleId, s)
			end
		else
			fail(puzzleId, s)
		end
	elseif cfg.kind == "together" then
		local now = os.clock()
		s.hits[netId] = now
		for _, t in cfg.targets do
			local at = s.hits[t]
			if at == nil or now - at > (cfg.window or 4) then
				return
			end
		end
		solve(puzzleId, s)
	end
end

function PuzzleService.start()
	for id, cfg in Puzzles do
		states[id] = { index = 1, hits = {}, locked = false, pending = 0, solvedAt = nil }
		for _, t in cfg.targets do
			byTarget[t] = id
		end
	end
	ToolService.onActivate(onActivate)
end

function PuzzleService.onSolved(fn: (puzzleId: string, players: { Player }) -> ())
	table.insert(solvedListeners, fn)
end

return PuzzleService
