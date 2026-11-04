--!strict
-- Bootstrap del cliente: arranca los Controllers en orden.
local Controllers = script.Parent:WaitForChild("Controllers")

local ToolController = require(Controllers:WaitForChild("ToolController"))
local CreatureController = require(Controllers:WaitForChild("CreatureController"))
local MaranaController = require(Controllers:WaitForChild("MaranaController"))

ToolController.start()
CreatureController.start()
MaranaController.start()
