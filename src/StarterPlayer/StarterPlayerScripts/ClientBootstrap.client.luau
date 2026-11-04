--!strict
-- Bootstrap del cliente: arranca los Controllers en orden.
local Controllers = script.Parent:WaitForChild("Controllers")

local ToolController = require(Controllers:WaitForChild("ToolController"))

ToolController.start()
