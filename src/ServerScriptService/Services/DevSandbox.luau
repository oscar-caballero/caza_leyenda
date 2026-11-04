--!strict
--[[
	DevSandbox — Escenario de pruebas SOLO EN STUDIO. En un servidor real no hace nada.

	Crea junto al spawn:
	  · Zona del pueblo (caja verde translúcida): ahí se puede cambiar de herramienta
	  · 3 Polillas de Papel (cubos blancos, nivel 3)  · Rumor (cubo gris grande, nivel 3)
	  · Chaneque (cubo verde, nivel 1): las herramientas NO deben hacerle nada
	  · Diana "Activable" (honda)  · Palanca "Giratorio" (yo-yo)
	  · Resortera (cilindro dorado): disparo rápido por 8 s
	  · Farol encendido (poste con luz): a menos de 8 studs la Maraña se vacía rápido
	Y regala 600 Semillas (en el Mock) para probar mejoras.

	Las criaturas de nivel 3 se registran en CreatureService (se mueven, huyen y reaparecen).
	El sandbox solo imprime en el Output lo que pasa.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"))
local CreatureService = require(script.Parent.CreatureService)
local DataService = require(script.Parent.DataService)
local MaranaService = require(script.Parent.MaranaService)
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

local function creature(folder: Folder, id: string, netId: string, pos: Vector3, size: number, color: Color3): Model
	local model = Instance.new("Model")
	model.Name = `{id} (prueba)`
	local body = part({ Name = "Body", Size = Vector3.one * size, Position = pos, Color = color }, model)
	model.PrimaryPart = body
	model:SetAttribute(Types.Attributes.CreatureId, id)
	model:SetAttribute(Types.Attributes.NetId, netId)
	model:SetAttribute(Types.Attributes.OlvidoMeter, 1)
	model:SetAttribute(Types.Attributes.EncounterState, "Idle")
	model.Parent = folder
	return model
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

	local paper = Color3.fromRGB(245, 240, 225)
	local level3 = {
		creature(folder, "PolillaPapel", "dev_polilla_1", Vector3.new(0, 4, -35), 2, paper),
		creature(folder, "PolillaPapel", "dev_polilla_2", Vector3.new(-8, 4, -40), 2, paper),
		creature(folder, "PolillaPapel", "dev_polilla_3", Vector3.new(8, 4, -40), 2, paper),
		creature(folder, "Rumor", "dev_rumor", Vector3.new(25, 6, -55), 8, Color3.fromRGB(150, 150, 160)),
	}
	-- Nivel 1: NO se registra en CreatureService; las herramientas no le hacen nada
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
	local farol = part({
		Name = "Farol (prueba)",
		Size = Vector3.new(0.8, 7, 0.8),
		Position = Vector3.new(-12, 3.5, 4),
		Color = Color3.fromRGB(60, 50, 40),
	}, folder)
	local light = part({
		Name = "Luz",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 1.6,
		Position = Vector3.new(-12, 7.5, 4),
		Color = Color3.fromRGB(255, 200, 110),
		Material = Enum.Material.Neon,
		CanCollide = false,
	}, folder)
	local glow = Instance.new("PointLight")
	glow.Range = 14
	glow.Color = light.Color
	glow.Parent = light
	MaranaService.setSafeResolver(function(pos)
		return (pos - farol.Position).Magnitude <= 8
	end)

	folder.Parent = workspace
	CollectionService:AddTag(resortera, Types.Tags.PowerUpResortera)

	for _, model in level3 do
		CreatureService.register(model)
		model:GetAttributeChangedSignal(Types.Attributes.EncounterState):Connect(function()
			print(`[DevSandbox] {model.Name} → {model:GetAttribute(Types.Attributes.EncounterState)}`)
		end)
	end

	ToolService.onHit(function(player, tool, model, damage)
		-- Corre después de CreatureService: el medidor ya está actualizado
		local meter = (model:GetAttribute(Types.Attributes.OlvidoMeter) :: number?) or 0
		print(
			`[DevSandbox] {player.Name} · {tool} → {model.Name}: -{string.format("%.1f", damage)}`
				.. ` · Olvido {math.floor(meter * 100)}%`
		)
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

	print("[DevSandbox] listo: 3 polillas, rumor, chaneque, diana, palanca, resortera, farol y zona del pueblo")
end

return DevSandbox
