--!strict
--[[
	CreatureController — Medidor de Olvido sobre las criaturas de nivel 3 (solo visual).

	Lee los atributos replicados por el servidor (OlvidoMeter, EncounterState); nunca escribe.
	No es una "barra de vida" (D-004): es una tira de papel que se vacía al disipar el Olvido.
	Muestra barra + porcentaje para no depender solo del color (D-011).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local CreaturesConfig = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))

local A = Types.Attributes
local INK = Color3.fromRGB(70, 60, 90)
local PAPER = Color3.fromRGB(245, 240, 225)

local CreatureController = {}

local tracked: { [Model]: boolean } = {}

local function attach(model: Model)
	if tracked[model] then
		return
	end
	local id = model:GetAttribute(A.CreatureId)
	local cfg = type(id) == "string" and CreaturesConfig[id] or nil
	if cfg == nil or cfg.level ~= 3 then
		return -- niveles 1 y 2 no tienen medidor: no se combaten
	end
	local adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if adornee == nil then
		return
	end
	tracked[model] = true

	local gui = Instance.new("BillboardGui")
	gui.Name = "OlvidoMeter"
	gui.Size = UDim2.fromOffset(110, 26)
	gui.StudsOffsetWorldSpace = Vector3.new(0, adornee.Size.Y / 2 + 2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	gui.Adornee = adornee

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 0.55)
	frame.BackgroundColor3 = INK
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = frame

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = PAPER
	fill.BorderSizePixel = 0
	fill.Parent = frame
	corner:Clone().Parent = fill

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 0.45)
	label.Position = UDim2.fromScale(0, 0.55)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	local function refresh()
		local meter = (model:GetAttribute(A.OlvidoMeter) :: number?) or 0
		local state = model:GetAttribute(A.EncounterState)
		fill.Size = UDim2.fromScale(math.clamp(meter, 0, 1), 1)
		label.Text = `Olvido {math.floor(meter * 100 + 0.5)}%`
		gui.Enabled = state ~= "Resolved"
	end
	refresh()
	model:GetAttributeChangedSignal(A.OlvidoMeter):Connect(refresh)
	model:GetAttributeChangedSignal(A.EncounterState):Connect(refresh)

	gui.Parent = adornee
	model.Destroying:Connect(function()
		tracked[model] = nil
	end)
end

local function consider(inst: Instance)
	if inst:IsA("Model") and inst:GetAttribute(A.CreatureId) ~= nil then
		attach(inst)
	end
end

function CreatureController.start()
	for _, inst in workspace:GetDescendants() do
		consider(inst)
	end
	workspace.DescendantAdded:Connect(function(inst)
		-- Los atributos y la PrimaryPart pueden llegar un instante después que el modelo
		task.defer(consider, inst)
	end)
end

return CreatureController
