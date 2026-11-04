--!strict
--[[
	QuestController — Muestra el objetivo actual (máx. 8 palabras, D-006) arriba al centro.
	Lo calcula del perfil (ProfileSync) y de los avisos del servidor; nunca decide nada.
	UI provisional hasta que UI/UX entregue el diseño final.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local QuestRules = require(Shared:WaitForChild("QuestRules"))
local Quests = require(Shared:WaitForChild("Config"):WaitForChild("Quests"))

local QuestController = {}

local label: TextLabel
local title: TextLabel
local current: { quest: string?, step: number, count: number, total: number } =
	{ quest = nil, step = 1, count = 0, total = 1 }
local celebrateUntil = 0

local function render()
	if os.clock() < celebrateUntil then
		return
	end
	local quest = current.quest
	if quest == nil then
		title.Text = ""
		label.Text = "¡Recuperaste las historias de la región!"
		return
	end
	local def = Quests.Defs[quest]
	local step = def and def.steps[current.step]
	title.Text = if def then def.title else ""
	if step == nil then
		label.Text = ""
	elseif current.total > 1 then
		label.Text = `{step.hint} ({current.count}/{current.total})`
	else
		label.Text = step.hint
	end
end

local function build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Objetivo"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, 10)
	frame.Size = UDim2.fromOffset(420, 58)
	frame.BackgroundColor3 = Color3.fromRGB(38, 35, 58)
	frame.BackgroundTransparency = 0.25
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(420, 58)
	limit.Parent = frame
	frame.Size = UDim2.new(0.8, 0, 0, 58)
	frame.Parent = gui

	title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 18)
	title.Position = UDim2.fromOffset(10, 5)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 196, 104)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 26)
	label.Position = UDim2.fromOffset(10, 26)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(245, 243, 236)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = frame

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function QuestController.start()
	build()

	Net.listen("ProfileSync", function(payload)
		local view = payload.view
		local quest = QuestRules.nextQuest(Quests.Order, view.CompletedQuests or {})
		local step = if quest then (view.QuestProgress or {})[quest] or 1 else 1
		if quest ~= current.quest or step ~= current.step then
			local def = quest and Quests.Defs[quest]
			local stepDef = def and def.steps[step]
			current = { quest = quest, step = step, count = 0, total = stepDef and stepDef.count or 1 }
		end
		render()
	end)

	Net.listen("Notice", function(payload)
		local args = payload.args or {}
		if payload.key == "Quest.Step" then
			current = { quest = args.quest, step = args.step, count = args.count or 0, total = args.total or 1 }
			render()
		elseif payload.key == "Quest.Completed" then
			local def = Quests.Defs[args.quest]
			celebrateUntil = os.clock() + 3
			title.Text = "¡Misión completada!"
			label.Text = if def then def.title else ""
			task.delay(3.05, render)
		elseif payload.key == "Puzzle.Failed" then
			print("[Acertijo] Las polillas se comieron la pista. ¡Disípalas!")
		elseif payload.key == "Puzzle.Solved" then
			print("[Acertijo] ¡Resuelto!")
		end
	end)
end

return QuestController
