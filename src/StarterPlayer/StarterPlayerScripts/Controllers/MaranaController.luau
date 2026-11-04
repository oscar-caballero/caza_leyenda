--!strict
--[[
	MaranaController — Cómo se VE la Maraña (D-019). Solo lee el atributo OlvidoMeter
	del Character (lo escribe el servidor); nunca decide nada.

	  · HUD: retrato arriba a la izquierda con 3 segmentos (lleno = papel con contorno,
	    vacío = hueco): se distingue por forma, no solo por color (D-011)
	  · Viñeta suave mientras TÚ estás Enredado
	  · Cuerpo de cada jugador: 33 % recortes de papel · 66 % brillo blanco · 100 % brillo fuerte
	    con contorno oscuro
	  · Mini-medidor sobre los COMPAÑEROS (nunca sobre ti: lo tapa el pulgar)

	Arte provisional: formas y colores definitivos los entrega el Artista 3D / UI.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Net = require(Shared:WaitForChild("Net"))
local MaranaConfig = require(Shared:WaitForChild("Config"):WaitForChild("Marana"))

local A = Types.Attributes
local SEG = MaranaConfig.SEGMENTS
local PAPER = Color3.fromRGB(245, 243, 236)
local INK = Color3.fromRGB(38, 35, 58)
local MAX_HIGHLIGHTS = 12 -- Roblox muestra 31 a la vez; dejamos margen para criaturas y efectos

local localPlayer = Players.LocalPlayer
local MaranaController = {}

local highlightsInUse = 0
local hudPips: { Frame } = {}
local vignette: Frame? = nil

local function segmentsFor(meter: number): number
	return math.clamp(math.floor(meter * SEG + 1e-9), 0, SEG)
end

local function paintPips(pips: { Frame }, filled: number)
	for i, pip in pips do
		local on = i <= filled
		pip.BackgroundTransparency = if on then 0 else 1
		local stroke = pip:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = if on then 2.5 else 1.5
		end
	end
end

local function makePips(parent: Instance, size: number, radius: number): { Frame }
	local pips = {}
	for i = 1, SEG do
		-- Repartidos alrededor del centro: 12, 4 y 8 en punto
		local angle = math.rad(-90 + (i - 1) * 360 / SEG)
		local pip = Instance.new("Frame")
		pip.Name = `Segmento{i}`
		pip.AnchorPoint = Vector2.new(0.5, 0.5)
		pip.Size = UDim2.fromOffset(size, size)
		pip.Position = UDim2.new(0.5, math.cos(angle) * radius, 0.5, math.sin(angle) * radius)
		pip.BackgroundColor3 = PAPER
		pip.BackgroundTransparency = 1
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.3, 0)
		corner.Parent = pip
		local stroke = Instance.new("UIStroke")
		stroke.Color = INK
		stroke.Thickness = 1.5
		stroke.Parent = pip
		pip.Parent = parent
		table.insert(pips, pip)
	end
	return pips
end

local function buildHud()
	local gui = Instance.new("ScreenGui")
	gui.Name = "MaranaHud"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.IgnoreGuiInset = false

	local holder = Instance.new("Frame")
	holder.Name = "Retrato"
	holder.Size = UDim2.fromOffset(64, 64)
	holder.Position = UDim2.fromOffset(12, 12)
	holder.BackgroundColor3 = INK
	holder.BackgroundTransparency = 0.2
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = holder
	holder.Parent = gui

	local face = Instance.new("ImageLabel")
	face.Size = UDim2.fromOffset(40, 40)
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.BackgroundTransparency = 1
	local faceCorner = Instance.new("UICorner")
	faceCorner.CornerRadius = UDim.new(1, 0)
	faceCorner.Parent = face
	face.Parent = holder
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(
				localPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size48x48
			)
		end)
		if ok then
			face.Image = image
		end
	end)

	hudPips = makePips(holder, 14, 29)

	local v = Instance.new("Frame")
	v.Name = "Vineta"
	v.Size = UDim2.fromScale(1, 1)
	v.BackgroundColor3 = PAPER
	v.BackgroundTransparency = 1
	v.ZIndex = 0
	local gradient = Instance.new("UIGradient")
	-- Bordes más opacos que el centro (viñeta suave, sin destellos: D-019)
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.25, 1),
		NumberSequenceKeypoint.new(0.75, 1),
		NumberSequenceKeypoint.new(1, 0.55),
	})
	gradient.Parent = v
	v.Parent = gui
	vignette = v

	gui.Parent = localPlayer:WaitForChild("PlayerGui")
end

-- Efectos en el cuerpo de un jugador (cualquiera, incluido uno mismo)
local function trackCharacter(player: Player, character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local head = character:WaitForChild("Head", 10)
	if root == nil or not root:IsA("BasePart") then
		return
	end

	local scraps = Instance.new("ParticleEmitter")
	scraps.Name = "RecortesDePapel"
	scraps.Color = ColorSequence.new(PAPER)
	scraps.LightEmission = 0.2
	scraps.Size = NumberSequence.new(0.25, 0.1)
	scraps.Lifetime = NumberRange.new(0.8, 1.4)
	scraps.Speed = NumberRange.new(1, 2.5)
	scraps.SpreadAngle = Vector2.new(180, 180)
	scraps.Rotation = NumberRange.new(0, 360)
	scraps.RotSpeed = NumberRange.new(-90, 90)
	scraps.Rate = 0
	scraps.Parent = root

	local highlight: Highlight? = nil
	local mini: { Frame }? = nil
	if player ~= localPlayer and head and head:IsA("BasePart") then
		local bb = Instance.new("BillboardGui")
		bb.Name = "MaranaCompanero"
		bb.Size = UDim2.fromOffset(44, 44)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 90
		bb.Adornee = head
		mini = makePips(bb, 10, 13)
		bb.Parent = head
	end

	local function refresh()
		local meter = (character:GetAttribute(A.OlvidoMeter) :: number?) or 0
		local segs = segmentsFor(meter)

		scraps.Rate = if segs >= 1 then 3 + segs * 3 else 0 -- ≤15 partículas vivas

		if segs >= 2 then
			if highlight == nil and highlightsInUse < MAX_HIGHLIGHTS then
				local h = Instance.new("Highlight")
				h.FillColor = PAPER
				h.OutlineColor = INK
				h.DepthMode = Enum.HighlightDepthMode.Occluded
				h.Parent = character
				highlight = h
				highlightsInUse += 1
			end
			if highlight then
				highlight.FillTransparency = if segs >= SEG then 0.35 else 0.65
				highlight.OutlineTransparency = if segs >= SEG then 0 else 0.5
			end
		elseif highlight then
			highlight:Destroy()
			highlight = nil
			highlightsInUse -= 1
		end

		if mini then
			paintPips(mini, segs)
		end
		if player == localPlayer then
			paintPips(hudPips, segs)
			if vignette then
				vignette.BackgroundTransparency = if segs >= SEG then 0.4 else 1
			end
		end
	end

	refresh()
	local conn = character:GetAttributeChangedSignal(A.OlvidoMeter):Connect(refresh)
	character.Destroying:Connect(function()
		conn:Disconnect()
		if highlight then
			highlightsInUse -= 1
			highlight = nil
		end
	end)
end

local function trackPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		trackCharacter(player, character)
	end)
	if player.Character then
		task.spawn(trackCharacter, player, player.Character)
	end
end

function MaranaController.start()
	buildHud()
	for _, p in Players:GetPlayers() do
		trackPlayer(p)
	end
	Players.PlayerAdded:Connect(trackPlayer)

	Net.listen("Notice", function(payload)
		if payload.key == "Player.Tangled" then
			print("[Maraña] ¡Enredado! Espera o pide ayuda a un compañero")
		elseif payload.key == "Player.Freed" then
			print(`[Maraña] libre ({payload.args and payload.args.reason})`)
		end
	end)
end

return MaranaController
