--!strict
--[[
	DataService — Único dueño del perfil persistente (D-009, D-017).

	  DataService.start()                         conecta Players y empieza a cargar perfiles
	  DataService.isLoaded(player)                true cuando su perfil está listo
	  DataService.waitForProfile(player, t?)      espera la carga; false si falló, se fue o pasó el tiempo
	  DataService.read(player)                    COPIA del perfil (solo lectura)
	  DataService.grantReward(player, id, fn)     recompensa idempotente
	  DataService.spendSeeds(player, n, fn)       cobro + efecto en un paso
	  DataService.update(player, fn)              cambio sin economía (equipar, avanzar misión)

	Nadie más escribe el perfil. Tras cada mutación: sanitización y ProfileSync (debounce 0.2 s).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Net = require(Shared:WaitForChild("Net"))
local ProfileStore = require(script.Parent.Parent.Vendor.ProfileStore)
local ProfileLogic = require(script.Parent.ProfileLogic)

local Logic = ProfileLogic.new(Types)

local STORE_NAME = "PlayerData"
local LOAD_TIMEOUT = 15 -- s
local SYNC_DEBOUNCE = 0.2 -- s

-- Mensajes al expulsar: texto fijo, nunca generado por jugadores
local KICK_LOAD_FAILED = "No pudimos cargar tu progreso. Intenta entrar de nuevo en un momento."
local KICK_SESSION_ENDED = "Tu partida se abrió en otro servidor. Vuelve a entrar para seguir jugando."
local KICK_NEWER_DATA = "Hay una versión más nueva del juego. Vuelve a entrar en un momento."

type Profile = any -- objeto Profile de ProfileStore (sin tipos exportados)
type Mutator = (draft: { [string]: any }) -> boolean?

local DataService = {}

local store: any = nil
local profiles: { [Player]: Profile } = {}
local loading: { [Player]: boolean } = {}
local syncPending: { [Player]: boolean } = {}

local function sendSync(player: Player)
	local profile = profiles[player]
	if profile == nil or not profile:IsActive() then
		return
	end
	Net.fire("ProfileSync", player, { view = Logic.toView(profile.Data) })
end

local function scheduleSync(player: Player)
	if syncPending[player] then
		return
	end
	syncPending[player] = true
	task.delay(SYNC_DEBOUNCE, function()
		syncPending[player] = nil
		if player.Parent == Players then
			sendSync(player)
		end
	end)
end

local function loadProfile(player: Player)
	if loading[player] or profiles[player] then
		return
	end
	loading[player] = true

	local deadline = os.clock() + LOAD_TIMEOUT
	local profile = store:StartSessionAsync(`Player_{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players or os.clock() > deadline
		end,
	})
	loading[player] = nil

	if profile == nil then
		if player.Parent == Players then
			player:Kick(KICK_LOAD_FAILED)
		end
		return
	end

	-- La versión se revisa ANTES de Reconcile: un perfil del futuro no se toca
	local migration = Logic.migrate(profile.Data)
	if migration ~= "ok" then
		warn(`[DataService] perfil {player.UserId} no migrable: {migration}`)
		profile:EndSession()
		if player.Parent == Players then
			player:Kick(if migration == "future" then KICK_NEWER_DATA else KICK_LOAD_FAILED)
		end
		return
	end

	profile:AddUserId(player.UserId) -- GDPR: permite borrar el perfil por UserId
	profile:Reconcile()
	Logic.sanitize(profile.Data)

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		if player.Parent == Players then
			player:Kick(KICK_SESSION_ENDED)
		end
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	profiles[player] = profile
	sendSync(player)

	if RunService:IsStudio() then
		local d = profile.Data
		print(
			`[DataService] perfil cargado (Mock): {player.UserId} · v{d.SchemaVersion} · nivel {d.Level} · `
				.. `{d.Seeds} Semillas · {d.Equipped.Slot1}/{d.Equipped.Slot2}`
		)
	end
end

local function onPlayerRemoving(player: Player)
	syncPending[player] = nil
	local profile = profiles[player]
	if profile then
		profiles[player] = nil
		profile:EndSession()
	end
end

------------------------------------------------------------------------
-- API pública
------------------------------------------------------------------------

function DataService.start()
	-- En Studio se usa el almacén simulado: las pruebas nunca tocan datos reales
	local root = ProfileStore.New(STORE_NAME, Types.newProfile())
	store = if RunService:IsStudio() then root.Mock else root

	Players.PlayerAdded:Connect(function(player)
		loadProfile(player)
	end)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(loadProfile, player)
	end
end

function DataService.isLoaded(player: Player): boolean
	return profiles[player] ~= nil
end

function DataService.waitForProfile(player: Player, timeout: number?): boolean
	local deadline = os.clock() + (timeout or LOAD_TIMEOUT + 5)
	while player.Parent == Players and profiles[player] == nil and os.clock() < deadline do
		task.wait(0.1)
	end
	return profiles[player] ~= nil
end

function DataService.read(player: Player): { [string]: any }?
	local profile = profiles[player]
	if profile == nil then
		return nil
	end
	return table.freeze(Logic.toView(profile.Data))
end

local function withProfile(player: Player, apply: (data: { [string]: any }) -> (boolean, string?)): (boolean, string?)
	local profile = profiles[player]
	if profile == nil or not profile:IsActive() then
		return false, "profile.notLoaded"
	end
	local ok, err = apply(profile.Data)
	if ok then
		profile.Data.LastSavedAt = os.time()
		scheduleSync(player)
	end
	return ok, err
end

function DataService.grantReward(player: Player, rewardId: string, fn: Mutator): (boolean, string?)
	return withProfile(player, function(data)
		return Logic.grantReward(data, rewardId, fn)
	end)
end

function DataService.spendSeeds(player: Player, amount: number, fn: Mutator): (boolean, string?)
	return withProfile(player, function(data)
		return Logic.spendSeeds(data, amount, fn)
	end)
end

function DataService.update(player: Player, fn: Mutator): (boolean, string?)
	return withProfile(player, function(data)
		return Logic.mutate(data, fn)
	end)
end

return DataService
