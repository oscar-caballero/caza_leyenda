--!strict
-- Bootstrap del servidor (D-009: Services propios, sin Knit). El orden importa.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Services = script.Parent:WaitForChild("Services")
local DataService = require(Services:WaitForChild("DataService"))
local ToolService = require(Services:WaitForChild("ToolService"))
local CreatureService = require(Services:WaitForChild("CreatureService"))
local MaranaService = require(Services:WaitForChild("MaranaService"))
local DevSandbox = require(Services:WaitForChild("DevSandbox"))

Net.startServer() -- 1. Remotes primero: DataService envía ProfileSync al cargar
DataService.start() -- 2. perfiles
ToolService.start() -- 3. servicios de juego (registran sus handlers con Net.on)
CreatureService.start() -- después de ToolService: se suscribe a sus golpes
MaranaService.start() -- después de ambos: usa sus ganchos (D-019)
DevSandbox.start() -- 4. solo en Studio: escenario de pruebas

Net.assertAllHandled()
