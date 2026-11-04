--!strict
--[[
	SliceBlockout — Greybox de la vertical slice (D-019): plaza y kiosco → camino al bosque → río.

	Bloques simples con todos los NetId que usan Config/Quests y Config/Puzzles. Se reemplaza
	por el arte del Artista 3D conservando los mismos NetId y tags. El cementerio queda fuera.

	Faroles: los de la plaza se encienden con la honda (tag Activable). Un farol encendido
	vacía la Maraña más rápido (MaranaService.addSafeResolver).

	Mapa (studs; el spawn está en el origen):
	  plaza y kiosco   z  -10 … -90
	  camino           z  -90 … -200   (Chaneque al final)
	  río              z -230 … -290
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Types"))
local ToolService = require(script.Parent.ToolService)
local MaranaService = require(script.Parent.MaranaService)
local WorldRegistry = require(script.Parent.WorldRegistry)
local AssetLibrary = require(script.Parent.AssetLibrary)

local SAFE_RADIUS = 10
local STONE = Color3.fromRGB(176, 168, 156)
local WOOD = Color3.fromRGB(110, 82, 60)
local DARK = Color3.fromRGB(52, 46, 60)
local LIT = Color3.fromRGB(255, 196, 104)
local UNLIT = Color3.fromRGB(120, 116, 128)

local SHAPES = {
	triangulo = { glyph = "▲", color = Color3.fromRGB(230, 120, 60) },
	circulo = { glyph = "●", color = Color3.fromRGB(70, 150, 220) },
	cuadro = { glyph = "■", color = Color3.fromRGB(120, 190, 90) },
}

local SliceBlockout = {}

local folder: Folder
local litFaroles: { [BasePart]: boolean } = {}

local function part(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = STONE
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = props.Parent or folder
	return p
end

local function label(parent: BasePart, text: string, color: Color3, size: number)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(size, size)
	bb.StudsOffsetWorldSpace = Vector3.new(0, parent.Size.Y / 2 + 1.5, 0)
	bb.MaxDistance = 120
	bb.AlwaysOnTop = false
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.2
	t.Font = Enum.Font.GothamBlack
	t.Parent = bb
	bb.Parent = parent
end

local originalTexture: { [BasePart]: string } = {}

local function setLit(head: BasePart, lit: boolean)
	if lit then
		litFaroles[head] = true
	else
		litFaroles[head] = nil
	end
	head.Color = if lit then LIT else UNLIT
	head.Material = if lit then Enum.Material.Neon else Enum.Material.SmoothPlastic
	if head:IsA("MeshPart") then
		-- Vidrio del farol real: encendido = brillo cálido sin textura; apagado = su textura
		originalTexture[head] = originalTexture[head] or head.TextureID
		head.TextureID = if lit then "" else originalTexture[head]
		head.Material = if lit then Enum.Material.Neon else Enum.Material.Glass
	end
	local light = head:FindFirstChildOfClass("PointLight")
	if light then
		light.Enabled = lit
	end
end

-- Farol: poste + cabeza. La cabeza es la que se activa y la que lleva el NetId.
local function farol(netId: string, base: Vector3, height: number, lit: boolean, activable: boolean): BasePart
	-- Modelo real si está importado (assets/roblox/Farol.rbxm); si no, bloques
	local model = AssetLibrary.clone("Farol", true)
	local head: BasePart
	if model then
		model.Name = `Farol {netId}`
		AssetLibrary.placeOnGround(model, base)
		model.Parent = folder
		head = model:FindFirstChild("Vidrio") :: BasePart
		head.Name = `Farol {netId}` -- el nombre "Farol ..." es el que enciende SliceBlockout
		head.CanCollide = false
	else
		part({
			Name = `Poste {netId}`,
			Size = Vector3.new(0.8, height, 0.8),
			Position = base + Vector3.new(0, height / 2, 0),
			Color = DARK,
		})
		head = part({
			Name = `Farol {netId}`,
			Size = Vector3.new(1.8, 1.8, 1.8),
			Position = base + Vector3.new(0, height + 0.9, 0),
			CanCollide = false,
		})
	end
	local light = Instance.new("PointLight")
	light.Range = 16
	light.Color = LIT
	light.Parent = head
	WorldRegistry.register(netId, head)
	if activable then
		CollectionService:AddTag(head, Types.Tags.Activable)
	end
	setLit(head, lit)
	return head
end

-- Objeto de acertijo con forma (▲ ● ■): se lee por forma, no solo por color (D-011)
local function shapedTarget(netId: string, pos: Vector3, shape: string, tag: string, size: Vector3)
	local s = SHAPES[shape]
	local p = part({ Name = netId, Size = size, Position = pos, Color = s.color })
	label(p, s.glyph, s.color, 46)
	CollectionService:AddTag(p, tag)
	WorldRegistry.register(netId, p)
end

-- Letrero con el orden de las formas: la "pista" que se comen las polillas
local function clueSign(netId: string, pos: Vector3, order: { string })
	local board = part({
		Name = `Pista {netId}`,
		Size = Vector3.new(9, 4, 0.5),
		Position = pos,
		Color = Color3.fromRGB(236, 230, 214),
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.PixelsPerStud = 40
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.GothamBlack
	t.TextColor3 = DARK
	local glyphs = {}
	for _, shape in order do
		table.insert(glyphs, SHAPES[shape].glyph)
	end
	t.Text = table.concat(glyphs, "  →  ")
	t.Parent = gui
	gui.Parent = board
	local front = gui:Clone()
	front.Face = Enum.NormalId.Front
	front.Parent = board
	WorldRegistry.register(netId, board)
end

local function anchor(netId: string, pos: Vector3)
	local p = part({
		Name = `Ancla {netId}`,
		Size = Vector3.one,
		Position = pos,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	WorldRegistry.register(netId, p)
end

local function buildPlaza()
	part({ Name = "Plaza", Size = Vector3.new(90, 1, 90), Position = Vector3.new(0, 0.5, -50) })
	local zone = part({
		Name = "ZonaPueblo (plaza)",
		Size = Vector3.new(90, 24, 90),
		Position = Vector3.new(0, 12, -50),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	CollectionService:AddTag(zone, Types.Tags.ZonaPueblo)

	-- Tutorial
	farol("farol_t1", Vector3.new(0, 1, -14), 7, true, false) -- ya encendido: enseña dónde se vacía la Maraña
	farol("plaza_farol_1", Vector3.new(-28, 1, -30), 7, false, true)
	farol("plaza_farol_2", Vector3.new(28, 1, -30), 7, false, true)
	farol("plaza_farol_3", Vector3.new(-28, 1, -75), 7, false, true)

	part({
		Name = "Tablero del pregón",
		Size = Vector3.new(6, 6, 0.6),
		Position = Vector3.new(14, 4, -22),
		Color = WOOD,
	})
	local pagina = part({
		Name = "Página del pregón",
		Size = Vector3.new(1.6, 2.2, 0.2),
		Position = Vector3.new(14, 4, -21.5),
		Color = Color3.fromRGB(240, 236, 224),
	})
	CollectionService:AddTag(pagina, Types.Tags.Giratorio)
	WorldRegistry.register("pagina_pregon", pagina)
	anchor("tutorial_polillas", Vector3.new(0, 4, -40))

	-- Kiosco con su farol alto (se enciende con la resortera)
	local kiosco = AssetLibrary.clone("Kiosco", true)
	if kiosco then
		-- La escalinata del modelo mira a -Z: se gira 180° para que dé hacia el spawn
		AssetLibrary.placeOnGround(kiosco, Vector3.new(0, 1, -55), math.pi)
		kiosco.Parent = folder
		farol("farol_kiosco", Vector3.new(0, AssetLibrary.top(kiosco), -55), 3, false, true)
	else
		part({
			Name = "Kiosco base",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2, 22, 22),
			Position = Vector3.new(0, 1.5, -55),
			Orientation = Vector3.new(0, 0, 90),
		})
		for i = 0, 5 do
			local a = math.rad(i * 60)
			part({
				Name = "Kiosco columna",
				Size = Vector3.new(0.8, 9, 0.8),
				Position = Vector3.new(math.cos(a) * 9, 7, -55 + math.sin(a) * 9),
				Color = WOOD,
			})
		end
		part({
			Name = "Kiosco techo",
			Size = Vector3.new(24, 1.2, 24),
			Position = Vector3.new(0, 12, -55),
			Color = DARK,
		})
		farol("farol_kiosco", Vector3.new(0, 12.6, -55), 3, false, true)
	end

	-- Resortera (power-up): el modelo real al doble de tamaño, girando; si no, el cilindro dorado
	local resorteraModel = AssetLibrary.clone("Resortera", false)
	local resortera: BasePart
	if resorteraModel then
		resorteraModel:ScaleTo(2)
		AssetLibrary.placeOnGround(resorteraModel, Vector3.new(8, 1.5, -38))
		resorteraModel.Parent = folder
		resortera = resorteraModel:FindFirstChildWhichIsA("BasePart") :: BasePart
		resortera.CanTouch = true
		local spinBase = resorteraModel:GetPivot()
		task.spawn(function()
			local t = 0
			while resorteraModel.Parent do
				t += task.wait()
				resorteraModel:PivotTo(spinBase * CFrame.new(0, math.sin(t * 2) * 0.3, 0) * CFrame.Angles(0, t, 0))
			end
		end)
	else
		resortera = part({
			Name = "Resortera",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1, 3, 3),
			Position = Vector3.new(8, 2.5, -38),
			Color = Color3.fromRGB(240, 200, 60),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
	end
	CollectionService:AddTag(resortera, Types.Tags.PowerUpResortera)

	-- M1: enjambres y manivelas (Giratorio → yo-yo)
	anchor("m1_enjambre_1", Vector3.new(-32, 4, -55))
	anchor("m1_enjambre_2", Vector3.new(32, 4, -55))
	anchor("m1_enjambre_3", Vector3.new(0, 4, -85))
	anchor("m1_manivelas", Vector3.new(0, 2, -72))
	clueSign("m1_pista", Vector3.new(0, 5, -68), { "circulo", "triangulo", "cuadro" })
	shapedTarget(
		"m1_manivela_triangulo",
		Vector3.new(-8, 2, -74),
		"triangulo",
		Types.Tags.Giratorio,
		Vector3.new(1.6, 3, 1.6)
	)
	shapedTarget(
		"m1_manivela_circulo",
		Vector3.new(0, 2, -76),
		"circulo",
		Types.Tags.Giratorio,
		Vector3.new(1.6, 3, 1.6)
	)
	shapedTarget("m1_manivela_cuadro", Vector3.new(8, 2, -74), "cuadro", Types.Tags.Giratorio, Vector3.new(1.6, 3, 1.6))
end

local function buildCamino()
	part({
		Name = "Camino al bosque",
		Size = Vector3.new(12, 1, 115),
		Position = Vector3.new(0, 0.5, -152),
		Color = Color3.fromRGB(150, 122, 90),
	})
	for i = 0, 7 do
		local z = -100 - i * 14
		part({
			Name = "Árbol",
			Size = Vector3.new(2, 12, 2),
			Position = Vector3.new(-14 - (i % 2) * 4, 6, z),
			Color = WOOD,
		})
		part({
			Name = "Árbol",
			Size = Vector3.new(2, 12, 2),
			Position = Vector3.new(14 + (i % 2) * 4, 6, z - 7),
			Color = WOOD,
		})
	end
	anchor("camino_inicio", Vector3.new(0, 2, -100))

	-- M2: señales (Activable → honda), orden ■ ▲ ●
	anchor("m2_senales", Vector3.new(0, 3, -145))
	clueSign("m2_pista", Vector3.new(0, 6, -128), { "cuadro", "triangulo", "circulo" })
	shapedTarget(
		"m2_senal_triangulo",
		Vector3.new(-10, 7, -145),
		"triangulo",
		Types.Tags.Activable,
		Vector3.new(2.5, 2.5, 0.6)
	)
	shapedTarget(
		"m2_senal_cuadro",
		Vector3.new(10, 7, -152),
		"cuadro",
		Types.Tags.Activable,
		Vector3.new(2.5, 2.5, 0.6)
	)
	shapedTarget(
		"m2_senal_circulo",
		Vector3.new(-10, 7, -160),
		"circulo",
		Types.Tags.Activable,
		Vector3.new(2.5, 2.5, 0.6)
	)

	-- El Chaneque (nivel 1): marcador provisional. Nunca se registra en CreatureService
	local chaneque = part({
		Name = "Chaneque (provisional)",
		Size = Vector3.new(2, 3, 2),
		Position = Vector3.new(0, 2.5, -198),
		Color = Color3.fromRGB(60, 150, 70),
	})
	chaneque:SetAttribute(Types.Attributes.CreatureId, "Chaneque")
	WorldRegistry.register("chaneque", chaneque)
end

local function buildRio()
	part({
		Name = "Orilla",
		Size = Vector3.new(120, 1, 30),
		Position = Vector3.new(0, 0.5, -222),
		Color = Color3.fromRGB(150, 140, 110),
	})
	part({
		Name = "Río",
		Size = Vector3.new(160, 1, 50),
		Position = Vector3.new(0, 0.2, -262),
		Color = Color3.fromRGB(70, 120, 170),
		Material = Enum.Material.Glass,
		Transparency = 0.3,
	})
	anchor("rio_orilla", Vector3.new(0, 2, -228))
	anchor("rio_rumor", Vector3.new(18, 6, -250))

	-- M3: dos compuertas (Giratorio → yo-yo) a 12 studs: un solo jugador alcanza ambas en 4 s
	anchor("m3_compuertas", Vector3.new(0, 2, -232))
	shapedTarget(
		"m3_compuerta_izq",
		Vector3.new(-6, 2, -234),
		"triangulo",
		Types.Tags.Giratorio,
		Vector3.new(1.6, 3, 1.6)
	)
	shapedTarget("m3_compuerta_der", Vector3.new(6, 2, -234), "circulo", Types.Tags.Giratorio, Vector3.new(1.6, 3, 1.6))
end

function SliceBlockout.start()
	folder = Instance.new("Folder")
	folder.Name = "VerticalSlice (greybox)"
	buildPlaza()
	buildCamino()
	buildRio()
	folder.Parent = workspace

	-- Los faroles se encienden con su herramienta y se quedan encendidos en este servidor
	ToolService.onActivate(function(_player, _tool, target)
		if target:IsA("BasePart") and litFaroles[target] == nil and string.sub(target.Name, 1, 6) == "Farol " then
			setLit(target, true)
		end
	end)

	MaranaService.addSafeResolver(function(pos)
		for head in litFaroles do
			local d = head.Position - pos
			if d.X * d.X + d.Z * d.Z <= SAFE_RADIUS * SAFE_RADIUS then
				return true
			end
		end
		return false
	end)
end

return SliceBlockout
