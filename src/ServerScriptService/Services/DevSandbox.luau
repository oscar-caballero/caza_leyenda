--!strict
--[[
	DevSandbox — Escenario de pruebas SOLO EN STUDIO. En un servidor real no hace nada.

	Crea junto al spawn:
	  · Zona del pueblo (caja verde translúcida): ahí se puede cambiar de herramienta
	  · Polilla de Papel (cubo blanco, nivel 3)  · Rumor (cubo gris grande, nivel 3)
	  · Chaneque (cubo verde, nivel 1): las herramientas NO deben hacerle nada
	  · Diana "Activable" (honda)  · Palanca "Giratorio" (yo-yo)
	  · Resortera (cilindro dorado): disparo rápido por 8 s
	Y regala 600 Semillas (en el Mock) para probar mejoras.

	Mientras no exista CreatureService, este sandbox escucha ToolService.onHit y baja
	el atributo OlvidoMeter de las criaturas de prueba.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"))
local CreaturesConfig = require(ReplicatedStorage.Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local DataService = require(script.Parent.DataService)
local ToolService = require(script.Parent.ToolService)

local DevSandbox = {}

local function part(props: { [string]: any }, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function creature(folder: Folder, id: string, netId: string, pos: Vector3, size: number, color: Color3)
	local model = Instance.new("Model")
	model.Name = `{id} (prueba)`
	local body = part({ Name = "Body", Size = Vector3.one * size, Position = pos, Color = color }, model)
	model.PrimaryPart = body
	model:SetAttribute(Types.Attributes.CreatureId, id)
	model:SetAttribute(Types.Attributes.NetId, netId)
	model:SetAttribute(Types.Attributes.OlvidoMeter, 1)
	model:SetAttribute(Types.Attributes.EncounterState, "Idle")
	model.Parent = folder
end

function DevSandbox.start()
	if not RunService:IsStudio() then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "DevSandbox"

	local zone = part({
		Name = "ZonaPueblo",
		Size = Vector3.new(40, 20, 40),
		Position = Vector3.new(0, 10, 0),
		Transparency = 0.9,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Color = Color3.fromRGB(80, 200, 120),
	}, folder)
	CollectionService:AddTag(zone, Types.Tags.ZonaPueblo)

	creature(folder, "PolillaPapel", "dev_polilla", Vector3.new(0, 4, -35), 3, Color3.fromRGB(245, 240, 225))
	creature(folder, "Rumor", "dev_rumor", Vector3.new(18, 6, -45), 8, Color3.fromRGB(150, 150, 160))
	creature(folder, "Chaneque", "dev_chaneque", Vector3.new(-14, 2, -22), 2.5, Color3.fromRGB(60, 150, 70))

	local diana = part({
		Name = "Diana (Activable)",
		Size = Vector3.new(4, 4, 1),
		Position = Vector3.new(-25, 8, -60),
		Color = Color3.fromRGB(220, 60, 60),
	}, folder)
	CollectionService:AddTag(diana, Types.Tags.Activable)

	local palanca = part({
		Name = "Palanca (Giratorio)",
		Size = Vector3.new(1.5, 3, 1.5),
		Position = Vector3.new(-6, 1.5, -14),
		Color = Color3.fromRGB(90, 90, 220),
	}, folder)
	CollectionService:AddTag(palanca, Types.Tags.Giratorio)

	local resortera = part({
		Name = "Resortera",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 3, 3),
		Position = Vector3.new(8, 1.5, -8),
		Color = Color3.fromRGB(240, 200, 60),
		Material = Enum.Material.Neon,
		CanCollide = false,
	}, folder)
	folder.Parent = workspace
	CollectionService:AddTag(resortera, Types.Tags.PowerUpResortera)

	-- Sustituto temporal de CreatureService
	ToolService.onHit(function(player, tool, model, damage)
		local cfg = CreaturesConfig[model:GetAttribute(Types.Attributes.CreatureId) :: string]
		local meter = (model:GetAttribute(Types.Attributes.OlvidoMeter) :: number?) or 1
		meter = math.max(0, meter - damage / (cfg.maxOlvido :: number))
		model:SetAttribute(Types.Attributes.OlvidoMeter, meter)
		print(
			`[DevSandbox] {player.Name} · {tool} → {model.Name}: -{string.format("%.1f", damage)} · Olvido {math.floor(
				meter * 100
			)}%`
		)
		if meter <= 0 then
			print(`[DevSandbox] {model.Name} disipada; reaparece en 3 s`)
			task.delay(3, function()
				model:SetAttribute(Types.Attributes.OlvidoMeter, 1)
			end)
		end
	end)

	ToolService.onActivate(function(player, tool, target)
		print(`[DevSandbox] {player.Name} activó {target.Name} con {tool}`)
		if target:IsA("BasePart") then
			local original = target.Color
			target.Color = Color3.fromRGB(255, 255, 120)
			task.delay(0.5, function()
				target.Color = original
			end)
		end
	end)

	local function gift(player: Player)
		if DataService.waitForProfile(player) then
			DataService.grantReward(player, "dev:seeds_600", function(d)
				d.Seeds += 600
				return true
			end)
		end
	end
	Players.PlayerAdded:Connect(gift)
	for _, p in Players:GetPlayers() do
		task.spawn(gift, p)
	end

	print("[DevSandbox] listo: polilla, rumor, chaneque, diana, palanca, resortera y zona del pueblo")
end

return DevSandbox
