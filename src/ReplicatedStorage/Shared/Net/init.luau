--!strict
--[[
	Net — Único punto de comunicación cliente-servidor (D-009, contratos D-016).

	Servidor:
	  Net.startServer()                      crea un Remote por contrato en ReplicatedStorage.NetRemotes
	  Net.setAnchorResolver(fn)              NetId → posición, para validar distancia
	  Net.on(name, handler)                  registra el handler de un Remote cliente→servidor
	  Net.assertAllHandled()                 lo llama el Bootstrap al terminar de iniciar servicios
	  Net.fire / Net.fireList / Net.fireAll  envía un Remote servidor→cliente

	Cliente:
	  Net.send(name, payload)                envía un Remote cliente→servidor
	  Net.listen(name, handler)              escucha un Remote servidor→cliente

	Filtro de cada evento entrante, en este orden (se corta en el primero que falle):
	  1. contrato conocido y con handler   2. exactamente un argumento
	  3. rate limit por jugador            4. esquema                5. distancia al ancla
	Los rechazos no responden nada al cliente: solo se cuentan y se registran en el log (con tope).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Contracts = require(script.Contracts)
local RateLimiter = require(script.RateLimiter)
local Schema = require(script.Schema)

type Contract = Contracts.Contract
export type Payload = { [string]: any }
export type ServerHandler = (player: Player, payload: Payload) -> ()
export type ClientHandler = (payload: Payload) -> ()
export type AnchorResolver = (netId: string) -> Vector3?

local FOLDER_NAME = "NetRemotes"
local LOG_EVERY = 50 -- tras el primer rechazo, registrar 1 de cada N por jugador y Remote

local Net = {}

------------------------------------------------------------------------
-- Estado interno
------------------------------------------------------------------------

local folder: Folder? = nil
local remotes: { [string]: RemoteEvent | UnreliableRemoteEvent } = {}
local handlers: { [string]: ServerHandler } = {}
local limiters: { [string]: RateLimiter.RateLimiter } = {}
local rejects: { [string]: number } = {} -- "<userId>:<remote>" → conteo
local anchorResolver: AnchorResolver? = nil
local serverStarted = false

local function getContract(name: string): Contract
	local c = Contracts[name]
	if c == nil then
		error(`Net: el Remote '{name}' no está registrado en Net/Contracts`, 3)
	end
	return c
end

local function reject(player: Player, name: string, reason: string)
	local key = `{player.UserId}:{name}`
	local n = (rejects[key] or 0) + 1
	rejects[key] = n
	if n == 1 or n % LOG_EVERY == 0 then
		warn(`[Net] rechazado {name} de {player.UserId} ({n}): {reason}`)
	end
end

local function checkDistance(player: Player, c: Contract, payload: Payload): (boolean, string?)
	local maxDistance = c.maxDistance
	if maxDistance == nil then
		return true, nil
	end
	local resolver = anchorResolver
	if resolver == nil then
		return false, "distance.noResolver"
	end
	local anchorPos = resolver(payload[c.anchorField :: string])
	if anchorPos == nil then
		return false, "distance.unknownAnchor"
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return false, "distance.noCharacter"
	end
	if (root.Position - anchorPos).Magnitude > maxDistance then
		return false, "distance.tooFar"
	end
	return true, nil
end

------------------------------------------------------------------------
-- Servidor
------------------------------------------------------------------------

function Net.startServer()
	assert(RunService:IsServer(), "Net.startServer solo en el servidor")
	assert(not serverStarted, "Net.startServer ya se llamó")
	serverStarted = true

	local f = Instance.new("Folder")
	f.Name = FOLDER_NAME

	for name, c in Contracts do
		local instance: Instance = if c.reliable
			then Instance.new("RemoteEvent")
			else Instance.new("UnreliableRemoteEvent")
		instance.Name = name
		instance.Parent = f
		local remote = instance :: RemoteEvent | UnreliableRemoteEvent
		remotes[name] = remote

		if c.direction == "ClientToServer" then
			limiters[name] = RateLimiter.new(c.rateLimit :: RateLimiter.Config, os.clock)
			local shape = c.schema

			local function onEvent(player: Player, ...: any)
				local handler = handlers[name]
				if handler == nil then
					reject(player, name, "noHandler")
					return
				end
				if select("#", ...) ~= 1 then
					reject(player, name, "argCount")
					return
				end
				if not limiters[name]:take(player.UserId) then
					reject(player, name, "rateLimit")
					return
				end
				local payload = ...
				local ok, err = Schema.validate(shape, payload)
				if not ok then
					reject(player, name, err :: string)
					return
				end
				local near, distErr = checkDistance(player, c, payload)
				if not near then
					reject(player, name, distErr :: string)
					return
				end
				handler(player, payload)
			end

			if remote:IsA("RemoteEvent") then
				remote.OnServerEvent:Connect(onEvent)
			else
				(remote :: UnreliableRemoteEvent).OnServerEvent:Connect(onEvent)
			end
		end
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		for _, limiter in limiters do
			limiter:remove(player.UserId)
		end
		local prefix = `{player.UserId}:`
		for key in rejects do
			if string.sub(key, 1, #prefix) == prefix then
				rejects[key] = nil
			end
		end
	end)

	-- Se publica al final, ya con todos los Remotes dentro
	f.Parent = ReplicatedStorage
	folder = f
end

function Net.setAnchorResolver(resolver: AnchorResolver)
	assert(RunService:IsServer(), "Net.setAnchorResolver solo en el servidor")
	anchorResolver = resolver
end

function Net.on(name: string, handler: ServerHandler)
	assert(RunService:IsServer(), "Net.on solo en el servidor")
	local c = getContract(name)
	assert(c.direction == "ClientToServer", `Net.on: '{name}' no es ClientToServer`)
	assert(handlers[name] == nil, `Net.on: '{name}' ya tiene handler`)
	handlers[name] = handler
end

function Net.assertAllHandled()
	for name, c in Contracts do
		if c.direction == "ClientToServer" and handlers[name] == nil then
			warn(`[Net] '{name}' no tiene handler: sus eventos se rechazarán`)
		end
	end
end

local function serverRemote(name: string, payload: Payload): RemoteEvent | UnreliableRemoteEvent
	assert(serverStarted, "Net: llama a Net.startServer() primero")
	local c = getContract(name)
	assert(c.direction == "ServerToClient", `Net: '{name}' no es ServerToClient`)
	if RunService:IsStudio() then
		local ok, err = Schema.validate(c.schema, payload, true)
		assert(ok, `Net: payload inválido para '{name}': {err}`)
	end
	return remotes[name]
end

function Net.fire(name: string, player: Player, payload: Payload)
	local remote = serverRemote(name, payload)
	if remote:IsA("RemoteEvent") then
		remote:FireClient(player, payload)
	else
		(remote :: UnreliableRemoteEvent):FireClient(player, payload)
	end
end

function Net.fireList(name: string, players: { Player }, payload: Payload)
	local remote = serverRemote(name, payload)
	for _, player in players do
		if remote:IsA("RemoteEvent") then
			remote:FireClient(player, payload)
		else
			(remote :: UnreliableRemoteEvent):FireClient(player, payload)
		end
	end
end

function Net.fireAll(name: string, payload: Payload)
	local remote = serverRemote(name, payload)
	if remote:IsA("RemoteEvent") then
		remote:FireAllClients(payload)
	else
		(remote :: UnreliableRemoteEvent):FireAllClients(payload)
	end
end

------------------------------------------------------------------------
-- Cliente
------------------------------------------------------------------------

local function clientRemote(name: string): RemoteEvent | UnreliableRemoteEvent
	assert(RunService:IsClient(), "Net: función solo para el cliente")
	local existing = remotes[name]
	if existing then
		return existing
	end
	local f = folder
	if f == nil then
		f = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
		folder = f
	end
	local remote = (f :: Folder):WaitForChild(name) :: RemoteEvent | UnreliableRemoteEvent
	remotes[name] = remote
	return remote
end

function Net.send(name: string, payload: Payload)
	local c = getContract(name)
	assert(c.direction == "ClientToServer", `Net.send: '{name}' no es ClientToServer`)
	-- Mismo esquema que el servidor: un error aquí es un bug nuestro, no del jugador
	local ok, err = Schema.validate(c.schema, payload)
	if not ok then
		warn(`[Net] payload inválido para '{name}': {err}`)
		return
	end
	local remote = clientRemote(name)
	if remote:IsA("RemoteEvent") then
		remote:FireServer(payload)
	else
		(remote :: UnreliableRemoteEvent):FireServer(payload)
	end
end

function Net.listen(name: string, handler: ClientHandler): RBXScriptConnection
	local c = getContract(name)
	assert(c.direction == "ServerToClient", `Net.listen: '{name}' no es ServerToClient`)
	local remote = clientRemote(name)
	if remote:IsA("RemoteEvent") then
		return remote.OnClientEvent:Connect(handler)
	end
	return (remote :: UnreliableRemoteEvent).OnClientEvent:Connect(handler)
end

return Net
