--!strict
-- Bootstrap del servidor (D-009: Services propios, sin Knit). El orden importa.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Services = script.Parent:WaitForChild("Services")
local DataService = require(Services:WaitForChild("DataService"))
local ToolService = require(Services:WaitForChild("ToolService"))
local CreatureService = require(Services:WaitForChild("CreatureService"))
local MaranaService = require(Services:WaitForChild("MaranaService"))
local WorldRegistry = require(Services:WaitForChild("WorldRegistry"))
local SliceBlockout = require(Services:WaitForChild("SliceBlockout"))
local PuzzleService = require(Services:WaitForChild("PuzzleService"))
local QuestService = require(Services:WaitForChild("QuestService"))
local DevSandbox = require(Services:WaitForChild("DevSandbox"))

Net.startServer() -- 1. Remotes primero: DataService envía ProfileSync al cargar
Net.setAnchorResolver(WorldRegistry.position) -- distancia de PuzzleSubmit y otros
DataService.start() -- 2. perfiles
ToolService.start() -- 3. servicios de juego (registran sus handlers con Net.on)
CreatureService.start() -- después de ToolService: se suscribe a sus golpes
MaranaService.start() -- después de ambos: usa sus ganchos (D-019)
SliceBlockout.start() -- 4. el mundo (greybox) registra sus NetId antes de las misiones
PuzzleService.start()
QuestService.start() -- 5. misiones: necesita mundo, acertijos y criaturas
DevSandbox.start() -- 6. solo en Studio: escenario de pruebas (a 250 studs en +X)

Net.assertAllHandled()
