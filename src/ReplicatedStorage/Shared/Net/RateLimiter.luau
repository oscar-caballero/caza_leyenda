--!strict
--[[
	Net/RateLimiter — Token bucket por clave (una clave = un jugador).

	Módulo PURO: el reloj se inyecta (os.clock en el servidor, reloj falso en tests).
	Cada Remote de cliente a servidor tiene su propio limitador.
]]

export type Config = {
	burst: number, -- tokens máximos acumulados
	perSecond: number, -- recarga por segundo
}

type Bucket = {
	tokens: number,
	last: number,
}

export type RateLimiter = {
	take: (self: RateLimiter, key: number) -> boolean,
	remove: (self: RateLimiter, key: number) -> (),
	size: (self: RateLimiter) -> number,
}

local RateLimiter = {}

function RateLimiter.new(config: Config, now: () -> number): RateLimiter
	assert(config.burst >= 1, "RateLimiter: burst debe ser >= 1")
	assert(config.perSecond > 0, "RateLimiter: perSecond debe ser > 0")

	local buckets: { [number]: Bucket } = {}
	local count = 0

	local self = {} :: RateLimiter

	function self.take(_: RateLimiter, key: number): boolean
		local t = now()
		local b = buckets[key]
		if b == nil then
			b = { tokens = config.burst, last = t }
			buckets[key] = b
			count += 1
		else
			-- Si el reloj retrocede, no se regalan tokens
			local elapsed = math.max(0, t - b.last)
			b.tokens = math.min(config.burst, b.tokens + elapsed * config.perSecond)
			b.last = t
		end

		if b.tokens >= 1 then
			b.tokens -= 1
			return true
		end
		return false
	end

	function self.remove(_: RateLimiter, key: number)
		if buckets[key] ~= nil then
			buckets[key] = nil
			count -= 1
		end
	end

	function self.size(_: RateLimiter): number
		return count
	end

	return self
end

return table.freeze(RateLimiter)
