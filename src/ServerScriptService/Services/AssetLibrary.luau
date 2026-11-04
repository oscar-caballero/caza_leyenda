--!strict
--[[
	AssetLibrary — Modelos 3D importados (assets/roblox/*.rbxm → ServerStorage.Assets, vía Rojo).

	Si un modelo no está, `clone` devuelve nil y quien lo pide usa su versión de bloques
	(greybox). Así el juego funciona con o sin arte.

	Los modelos se importan SIN anclar: aquí se anclan y se les pone un pivote predecible
	(centro de su caja), opcionalmente girado 180° si el modelo mira hacia +Z.
]]

local ServerStorage = game:GetService("ServerStorage")

local AssetLibrary = {}

-- Modelos cuyo frente quedó hacia +Z al exportar (cabeza de la polilla); el código mueve
-- las criaturas con CFrame.lookAt, que usa -Z como frente.
local FACES_PLUS_Z: { [string]: boolean } = {
	PolillaPapel = true,
}

function AssetLibrary.has(name: string): boolean
	local folder = ServerStorage:FindFirstChild("Assets")
	return folder ~= nil and folder:FindFirstChild(name) ~= nil
end

--[[
	Clona el modelo `name`, ancla sus piezas y centra su pivote.
	  collide: si las piezas chocan (escenario sí, criaturas no)
]]
function AssetLibrary.clone(name: string, collide: boolean): Model?
	local folder = ServerStorage:FindFirstChild("Assets")
	local source = folder and folder:FindFirstChild(name)
	if source == nil or not source:IsA("Model") then
		return nil
	end
	local model = source:Clone()
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = collide
		end
	end
	local center = model:GetBoundingBox()
	local pivot = CFrame.new(center.Position)
	if FACES_PLUS_Z[name] then
		pivot *= CFrame.Angles(0, math.pi, 0)
	end
	model.WorldPivot = pivot
	return model
end

-- Coloca el modelo con la base de su caja en `ground` (y gira `yaw` radianes)
function AssetLibrary.placeOnGround(model: Model, ground: Vector3, yaw: number?)
	local _, size = model:GetBoundingBox()
	model:PivotTo(CFrame.new(ground + Vector3.new(0, size.Y / 2, 0)) * CFrame.Angles(0, yaw or 0, 0))
end

-- Altura del punto más alto del modelo (para poner algo encima, p. ej. el farol del kiosco)
function AssetLibrary.top(model: Model): number
	local cf, size = model:GetBoundingBox()
	return cf.Position.Y + size.Y / 2
end

return AssetLibrary
