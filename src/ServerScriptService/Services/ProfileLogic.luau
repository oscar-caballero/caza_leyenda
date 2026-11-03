--!strict
--[[
	ProfileLogic — Reglas puras del perfil persistente (D-017).

	Sin servicios de Roblox: se prueba en Lune. Recibe el módulo Types por inyección
	(ProfileLogic.new(Types)) porque `require(script...)` no existe fuera de Roblox.

	  migrate(data)                    sube SchemaVersion paso a paso; "future" si viene de un servidor más nuevo
	  sanitize(profile)                aplica tipos y topes; elimina ids desconocidos (en el lugar)
	  mutate(profile, fn)              aplica fn sobre una copia y solo si no falla la escribe (atómico)
	  grantReward(profile, id, fn)     idempotente por RewardId
	  spendSeeds(profile, n, fn)       cobra y aplica en un solo paso, o nada
	  toView(profile)                  copia para el cliente (sin ClaimedRewards ni metadatos)
]]

local ProfileLogic = {}

-- Migraciones: MIGRATIONS[n] convierte un perfil de versión n a n+1.
-- Vacía en v1. Cada entrada nueva requiere aprobación humana (D-010) y su test.
local MIGRATIONS: { [number]: (data: { [string]: any }) -> () } = {}

export type MigrateResult = "ok" | "future" | "invalid"

local function deepCopy<T>(v: T): T
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k, item in v :: any do
		out[deepCopy(k)] = deepCopy(item)
	end
	return out :: any
end

local function isFiniteNumber(v: unknown): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function clampInt(v: unknown, min: number, max: number, default: number): number
	if not isFiniteNumber(v) then
		return default
	end
	return math.clamp(math.floor(v :: number), min, max)
end

-- Conjunto { [string]: true }: deja solo claves string con valor true
local function cleanSet(v: unknown, maxLen: number?): { [string]: true }
	local out: { [string]: true } = {}
	if type(v) ~= "table" then
		return out
	end
	for k, flag in v :: { [any]: any } do
		if type(k) == "string" and flag == true and (maxLen == nil or #k <= maxLen) then
			out[k] = true
		end
	end
	return out
end

function ProfileLogic.new(Types: any)
	local Limits = Types.Limits
	local ToolIds: { string } = Types.ToolIds
	local CreatureIds: { string } = Types.CreatureIds
	local LoreLayers: { string } = Types.LoreLayers
	local CURRENT: number = Types.SCHEMA_VERSION

	local Logic = {}

	function Logic.migrate(data: { [string]: any }): MigrateResult
		local version = data.SchemaVersion
		if version == nil then
			-- Perfil recién creado por ProfileStore a partir de la plantilla
			data.SchemaVersion = CURRENT
			return "ok"
		end
		if not isFiniteNumber(version) or math.floor(version) ~= version or version < 1 then
			return "invalid"
		end
		if version > CURRENT then
			return "future"
		end
		while data.SchemaVersion < CURRENT do
			local step = MIGRATIONS[data.SchemaVersion]
			if step == nil then
				return "invalid"
			end
			step(data)
			data.SchemaVersion += 1
		end
		return "ok"
	end

	function Logic.sanitize(p: { [string]: any })
		local defaults = Types.newProfile()

		p.SchemaVersion = CURRENT
		p.Level = clampInt(p.Level, 1, Limits.MAX_LEVEL, 1)
		p.Experience = clampInt(p.Experience, 0, math.huge, 0)
		p.TutorialDone = p.TutorialDone == true
		p.Seeds = clampInt(p.Seeds, 0, Limits.MAX_SEEDS, 0)
		p.Fragments = cleanSet(p.Fragments, 64)
		p.CompletedQuests = cleanSet(p.CompletedQuests, 64)
		p.ClaimedRewards = cleanSet(p.ClaimedRewards, 96)
		p.LastSavedAt = clampInt(p.LastSavedAt, 0, math.huge, 0)

		-- Herramientas: exactamente las conocidas, nivel 0..MAX
		local tiers = if type(p.ToolTiers) == "table" then p.ToolTiers else {}
		local cleanTiers = {}
		for _, id in ToolIds do
			cleanTiers[id] = clampInt(tiers[id], 0, Limits.MAX_TOOL_TIER, 0)
		end
		p.ToolTiers = cleanTiers

		-- Ranuras: herramientas válidas y distintas
		local eq = if type(p.Equipped) == "table" then p.Equipped else {}
		local s1 = if table.find(ToolIds, eq.Slot1) then eq.Slot1 else defaults.Equipped.Slot1
		local s2 = if table.find(ToolIds, eq.Slot2) then eq.Slot2 else defaults.Equipped.Slot2
		if s1 == s2 then
			for _, id in ToolIds do
				if id ~= s1 then
					s2 = id
					break
				end
			end
		end
		p.Equipped = { Slot1 = s1, Slot2 = s2 }

		-- Bestiario: solo criaturas y capas conocidas
		local bestiary = if type(p.Bestiary) == "table" then p.Bestiary else {}
		local cleanBestiary = {}
		for _, creature in CreatureIds do
			local entry = bestiary[creature]
			if type(entry) == "table" and type(entry.Layers) == "table" then
				local layers = {}
				local any = false
				for _, layer in LoreLayers do
					if entry.Layers[layer] == true then
						layers[layer] = true
						any = true
					end
				end
				if any then
					cleanBestiary[creature] = { Layers = layers }
				end
			end
		end
		p.Bestiary = cleanBestiary

		-- Misiones abiertas: paso entero positivo; una misión completada no sigue abierta
		local progress = if type(p.QuestProgress) == "table" then p.QuestProgress else {}
		local cleanProgress = {}
		for k, step in progress do
			if type(k) == "string" and #k <= 64 and p.CompletedQuests[k] == nil and isFiniteNumber(step) then
				local n = math.floor(step)
				if n >= 1 then
					cleanProgress[k] = n
				end
			end
		end
		p.QuestProgress = cleanProgress

		-- Inventario: cantidades 1..MAX_STACK y como máximo MAX_INVENTORY_STACKS (orden estable)
		local inv = if type(p.Inventory) == "table" then p.Inventory else {}
		local keys = {}
		for k, n in inv do
			if type(k) == "string" and #k <= 64 and isFiniteNumber(n) and math.floor(n) >= 1 then
				table.insert(keys, k)
			end
		end
		table.sort(keys)
		local cleanInv = {}
		for i = 1, math.min(#keys, Limits.MAX_INVENTORY_STACKS) do
			local k = keys[i]
			cleanInv[k] = math.min(math.floor(inv[k]), Limits.MAX_STACK)
		end
		p.Inventory = cleanInv

		-- Ropa: ids string o nada
		local clothing = if type(p.Clothing) == "table" then p.Clothing else {}
		p.Clothing = {
			Appearance = if type(clothing.Appearance) == "string" then clothing.Appearance else nil,
			Effect = if type(clothing.Effect) == "string" then clothing.Effect else nil,
		}

		-- Fuera cualquier campo que no esté en el esquema
		for k in p do
			if defaults[k] == nil and k ~= "Clothing" then
				p[k] = nil
			end
		end
	end

	--[[
		Aplica fn sobre una copia profunda. Si fn falla o devuelve false, el perfil
		queda intacto. Si termina bien, se sanitiza la copia y se escribe en el mismo
		objeto (ProfileStore guarda la tabla Data, no se puede reemplazar).
	]]
	function Logic.mutate(p: { [string]: any }, fn: (draft: { [string]: any }) -> boolean?): (boolean, string?)
		local draft = deepCopy(p)
		local ok, result = pcall(fn, draft)
		if not ok then
			return false, `mutate.error: {result}`
		end
		if result == false then
			return false, "mutate.aborted"
		end
		Logic.sanitize(draft)
		for k in p do
			p[k] = nil
		end
		for k, v in draft do
			p[k] = v
		end
		return true, nil
	end

	function Logic.grantReward(
		p: { [string]: any },
		rewardId: string,
		fn: (draft: { [string]: any }) -> boolean?
	): (boolean, string?)
		if type(rewardId) ~= "string" or rewardId == "" or #rewardId > 96 then
			return false, "reward.invalidId"
		end
		if p.ClaimedRewards and p.ClaimedRewards[rewardId] then
			return false, "reward.alreadyClaimed"
		end
		return Logic.mutate(p, function(draft)
			local result = fn(draft)
			if result == false then
				return false
			end
			draft.ClaimedRewards[rewardId] = true
			return true
		end)
	end

	function Logic.spendSeeds(
		p: { [string]: any },
		amount: number,
		fn: (draft: { [string]: any }) -> boolean?
	): (boolean, string?)
		if not isFiniteNumber(amount) or amount < 1 or math.floor(amount) ~= amount then
			return false, "seeds.invalidAmount"
		end
		if (p.Seeds or 0) < amount then
			return false, "seeds.insufficient"
		end
		return Logic.mutate(p, function(draft)
			draft.Seeds -= amount
			return fn(draft)
		end)
	end

	function Logic.toView(p: { [string]: any }): { [string]: any }
		local view = deepCopy(p)
		view.ClaimedRewards = nil
		view.SchemaVersion = nil
		view.LastSavedAt = nil
		return view
	end

	return table.freeze(Logic)
end

return table.freeze(ProfileLogic)
