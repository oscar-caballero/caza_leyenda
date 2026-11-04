--!strict
-- Bootstrap del cliente: arranca los Controllers en orden.
local Controllers = script.Parent:WaitForChild("Controllers")

local ToolController = require(Controllers:WaitForChild("ToolController"))
local CreatureController = require(Controllers:WaitForChild("CreatureController"))
local MaranaController = require(Controllers:WaitForChild("MaranaController"))
local QuestController = require(Controllers:WaitForChild("QuestController"))

ToolController.start()
CreatureController.start()
MaranaController.start()
QuestController.start()
