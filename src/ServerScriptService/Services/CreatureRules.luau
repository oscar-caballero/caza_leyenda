--!strict
--[[
	CreatureRules — Reglas puras de criaturas y progresión (sin servicios de Roblox; se prueba en Lune).
	Usa Vector3 solo como valor (aritmética y :Lerp), que Lune también provee.
]]

local CreatureRules = {}

------------------------------------------------------------------------
-- Progresión (D-007): pasar del nivel n al n+1 cuesta 100·n^1.5 XP. Nivel máximo 6.
------------------------------------------------------------------------

function CreatureRules.xpToNext(level: number): number
	return math.floor(100 * level ^ 1.5)
end

function CreatureRules.levelForXp(xp: number, maxLevel: number): number
	local level = 1
	local needed = 0
	while level < maxLevel do
		needed += CreatureRules.xpToNext(level)
		if xp < needed then
			break
		end
		level += 1
	end
	return level
end

------------------------------------------------------------------------
-- Cooperativo (D-008 23.7): escala con el grupo CERCANO, tope n=4 → ×2.5
------------------------------------------------------------------------

function CreatureRules.coopScale(nearbyPlayers: number): number
	local n = math.clamp(math.floor(nearbyPlayers), 1, 4)
	return 1 + 0.5 * (n - 1)
end

-- Nuevo medidor (0..1) tras `damage` puntos, con maxOlvido escalado por el grupo
function CreatureRules.applyDamage(meter: number, damage: number, maxOlvido: number, scale: number): number
	if damage <= 0 then
		return meter
	end
	local result = meter - damage / (maxOlvido * scale)
	-- Residuos de punto flotante (p. ej. 3 × 1/3 deja 1e-16): cuentan como disipada
	if result < 1e-6 then
		return 0
	end
	return result
end

-- Quiénes reciben recompensa: aportaron al menos `minShare` del daño total
function CreatureRules.eligible<K>(contributions: { [K]: number }, minShare: number): { K }
	local total = 0
	for _, d in contributions do
		total += d
	end
	local out = {}
	if total <= 0 then
		return out
	end
	for who, d in contributions do
		if d / total >= minShare then
			table.insert(out, who)
		end
	end
	return out
end

------------------------------------------------------------------------
-- Rebobinado (D-009): historial de posiciones y prueba rayo-esfera
------------------------------------------------------------------------

export type Sample = { t: number, pos: Vector3 }

-- Posición interpolada en el tiempo t (fuera del rango se usa el extremo más cercano)
function CreatureRules.positionAt(history: { Sample }, t: number): Vector3?
	local n = #history
	if n == 0 then
		return nil
	end
	if t <= history[1].t then
		return history[1].pos
	end
	if t >= history[n].t then
		return history[n].pos
	end
	for i = 2, n do
		local b = history[i]
		if t <= b.t then
			local a = history[i - 1]
			local span = b.t - a.t
			local alpha = if span > 0 then (t - a.t) / span else 1
			return a.pos:Lerp(b.pos, alpha)
		end
	end
	return history[n].pos
end

-- Quita las muestras más viejas que `keep` segundos respecto a `now`
function CreatureRules.trimHistory(history: { Sample }, now: number, keep: number)
	local cut = 0
	for i, s in history do
		if now - s.t > keep then
			cut = i
		else
			break
		end
	end
	if cut > 0 then
		-- Conservar una muestra anterior al corte para poder interpolar justo en el borde
		for _ = 1, cut - 1 do
			table.remove(history, 1)
		end
	end
end

-- Distancia a lo largo del rayo hasta la esfera, o nil si no la toca dentro de `range`
function CreatureRules.raySphere(origin: Vector3, dir: Vector3, range: number, center: Vector3, radius: number): number?
	local oc = center - origin
	local along = oc:Dot(dir)
	if along < 0 then
		return nil
	end
	local closest2 = oc:Dot(oc) - along * along
	local r2 = radius * radius
	if closest2 > r2 then
		return nil
	end
	local dist = along - math.sqrt(r2 - closest2)
	if dist > range then
		return nil
	end
	return math.max(0, dist)
end

-- Tiempo de rebobinado permitido: el del cliente, recortado a [now - maxRewind, now]
function CreatureRules.rewindTime(clientTime: number, now: number, maxRewind: number): number
	return math.clamp(clientTime, now - maxRewind, now)
end

return table.freeze(CreatureRules)
