--!strict
--[[
	ToolController — Herramientas del lado del cliente.

	El cliente solo PIDE: manda la dirección de apuntado y pinta un efecto local
	(predicción visual, D-009). El servidor decide si hubo golpe.

	Controles:
	  Clic / toque en el botón / R2      usar la herramienta activa
	  Q / botón Y / 1 y 2                cambiar entre las 2 ranuras
	  Solo en Studio (hasta que exista la UI):
	    T  intercambia las ranuras en el servidor (ToolEquip; solo dentro del pueblo)
	    U  mejora la herramienta activa (ToolUpgrade)
]]

local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local ToolsConfig = require(Shared:WaitForChild("Config"):WaitForChild("Tools"))

local player = Players.LocalPlayer
local AIM_DISTANCE = 300

local ToolController = {}

local view: { [string]: any }? = nil
local activeSlot = 1
local lastUse: { [string]: number } = {}

local function activeTool(): string?
	if view == nil then
		return nil
	end
	return if activeSlot == 1 then view.Equipped.Slot1 else view.Equipped.Slot2
end

local function headPosition(): Vector3?
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	return if head and head:IsA("BasePart") then head.Position else nil
end

local function toColor(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

-- Rayo visual (solo efecto): forma distinta por herramienta, además del color (D-011: no depender solo del color)
local function drawShot(tool: string, origin: Vector3, aim: Vector3, boosted: boolean)
	local def = ToolsConfig.Defs[tool]
	if def == nil then
		return
	end
	local length = def.range
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.Material = Enum.Material.Neon
	beam.Color = toColor(def.color)
	if tool == "Yoyo" then
		beam.Shape = Enum.PartType.Cylinder -- cuerda gruesa y corta
		beam.Size = Vector3.new(length, 0.35, 0.35)
		beam.CFrame = CFrame.lookAt(origin + aim * length / 2, origin + aim * length)
			* CFrame.Angles(0, math.rad(90), 0)
	else
		local thickness = if boosted then 0.15 else 0.25 -- la resortera se ve más fina y rápida
		beam.Size = Vector3.new(thickness, thickness, length)
		beam.CFrame = CFrame.lookAt(origin + aim * length / 2, origin + aim * length)
	end
	beam.Parent = workspace
	Debris:AddItem(beam, 0.12)
end

local function aimDirection(screenPos: Vector2?): Vector3?
	local camera = workspace.CurrentCamera
	local head = headPosition()
	if camera == nil or head == nil then
		return nil
	end
	local point = screenPos or (camera.ViewportSize / 2)
	local ray = camera:ViewportPointToRay(point.X, point.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * AIM_DISTANCE, params)
	local target = if hit then hit.Position else ray.Origin + ray.Direction * AIM_DISTANCE
	local dir = target - head
	if dir.Magnitude < 0.01 then
		return nil
	end
	return dir.Unit
end

local function useTool(screenPos: Vector2?)
	local tool = activeTool()
	if tool == nil then
		return
	end
	local def = ToolsConfig.Defs[tool]
	if def == nil or not def.enabled then
		return
	end
	-- Límite local optimista (la resortera puede reducirlo a la mitad); el servidor manda
	local now = os.clock()
	if now - (lastUse[tool] or -math.huge) < def.cooldown * ToolsConfig.Resortera.cooldownMult then
		return
	end
	local aim = aimDirection(screenPos)
	local head = headPosition()
	if aim == nil or head == nil then
		return
	end
	lastUse[tool] = now
	drawShot(tool, head, aim, false)
	Net.send("ToolUse", { tool = tool, aim = aim, clientTime = workspace:GetServerTimeNow() })
end

function ToolController.start()
	Net.listen("ProfileSync", function(payload)
		view = payload.view
	end)

	Net.listen("ToolFx", function(payload)
		drawShot(payload.tool, payload.origin, payload.aim, payload.boosted)
	end)

	Net.listen("Notice", function(payload)
		-- Hasta que exista la UI de avisos
		print(`[Aviso] {payload.key}`, payload.args)
	end)

	ContextActionService:BindAction("UseTool", function(_, state, input)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		local pos: Vector2? = nil
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			pos = UserInputService:GetMouseLocation()
		end
		useTool(pos)
		return Enum.ContextActionResult.Sink
	end, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
	ContextActionService:SetTitle("UseTool", "Usar")

	ContextActionService:BindAction("SwitchTool", function(_, state, input)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if input.KeyCode == Enum.KeyCode.One then
			activeSlot = 1
		elseif input.KeyCode == Enum.KeyCode.Two then
			activeSlot = 2
		else
			activeSlot = if activeSlot == 1 then 2 else 1
		end
		print(`[Herramienta] activa: {activeTool()}`)
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonY, Enum.KeyCode.One, Enum.KeyCode.Two)
	ContextActionService:SetTitle("SwitchTool", "Cambiar")

	if RunService:IsStudio() then
		ContextActionService:BindAction("DevEquipSwap", function(_, state)
			if state == Enum.UserInputState.Begin and view then
				Net.send("ToolEquip", { slot = 1, tool = view.Equipped.Slot2 })
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.T)

		ContextActionService:BindAction("DevUpgrade", function(_, state)
			local tool = activeTool()
			if state == Enum.UserInputState.Begin and tool then
				Net.send("ToolUpgrade", { tool = tool })
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.U)
	end
end

return ToolController
