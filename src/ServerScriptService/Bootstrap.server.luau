--!strict
-- Bootstrap del servidor (D-009: Services propios, sin Knit). El orden importa.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Services = script.Parent:WaitForChild("Services")
local DataService = require(Services:WaitForChild("DataService"))

Net.startServer() -- 1. Remotes primero: DataService envía ProfileSync al cargar
DataService.start() -- 2. perfiles
-- 3. aquí se registran los servicios de juego (ToolService, QuestService...) con Net.on

Net.assertAllHandled()
