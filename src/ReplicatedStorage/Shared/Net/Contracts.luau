--!strict
--[[
	Net/Contracts — Registro único de Remotes (APROBADO v1.0, 2026-11-03 — D-016)

	ESTADO: APROBADO y CONGELADO (D-016). Cambios solo con una decisión nueva en docs/decisiones.md.

	Reglas (D-009):
	  1. Solo existen los Remotes de esta tabla. El módulo Net crea las instancias
	     al arrancar el servidor; un Remote no registrado se rechaza y se registra en el log.
	  2. Solo RemoteEvent / UnreliableRemoteEvent. No hay RemoteFunction:
	     el servidor nunca espera al cliente y el cliente no puede colgar un hilo del servidor.
	  3. Todo lo que va del cliente al servidor tiene esquema, rate limit (token bucket
	     por jugador y por Remote) y, si toca el mundo, validación de distancia.
	  4. El cliente PIDE; el servidor decide. Ningún payload trae daño, Semillas,
	     recompensas, posición del jugador ni resultado de un acertijo.
	  5. Lo que puede ir sin Remote, va sin Remote:
	       - interacciones con NPC y objetos → ProximityPrompt.Triggered (servidor)
	       - recoger la resortera            → Touched/zona en el servidor
	       - medidor de Olvido y estado      → atributos replicados (Types.Attributes)
	       - diálogos                        → solo cliente; la misión avanza por eventos de servidor
]]

local Types = require(script.Parent.Parent.Types)

local Schema = require(script.Parent.Schema)

-- Única definición de los descriptores: Net/Schema (aquí solo se reexporta)
export type FieldSchema = Schema.FieldSchema

export type Direction = "ClientToServer" | "ServerToClient"

export type RateLimit = {
	burst: number, -- tokens máximos acumulados
	perSecond: number, -- recarga
}

export type Contract = {
	direction: Direction,
	reliable: boolean, -- false → UnreliableRemoteEvent (solo efectos visuales)
	schema: { [string]: FieldSchema },
	rateLimit: RateLimit?, -- obligatorio en ClientToServer
	maxDistance: number?, -- studs entre el personaje y la instancia de `anchorField`
	anchorField: string?, -- campo con un NetId cuya posición conoce el servidor
	notes: string,
}

-- Las listas de Types son { ToolId } (unión de literales) y el esquema guarda { string }.
-- Las tablas en Luau son invariantes, así que se convierte una vez aquí.
local function enum(values: { any }): FieldSchema
	return { kind = "enum", values = table.clone(values) :: { string } }
end

local NET_ID: FieldSchema = { kind = "string", maxLen = 64, pattern = "^[%w_%.%-]+$" }

local Contracts: { [string]: Contract } = {
	--------------------------------------------------------------------
	-- Cliente → Servidor (5)
	--------------------------------------------------------------------

	ToolUse = {
		direction = "ClientToServer",
		reliable = true,
		schema = {
			tool = enum(Types.ToolIds),
			aim = { kind = "unitVector3" },
			-- marca de tiempo del cliente para el rebobinado (D-009: máx. 250 ms).
			-- El servidor recorta al rango [ahora-0.25, ahora]; nunca confía en ella más allá.
			clientTime = { kind = "number", min = 0, max = 1e10 },
			hitHint = { kind = "optional", of = NET_ID }, -- pista; el servidor hace su propio raycast
		},
		rateLimit = { burst = 8, perSecond = 5 }, -- por encima del cooldown real; el cooldown lo impone el servidor
		notes = "El servidor exige que la herramienta esté equipada, aplica cooldown, "
			.. "resortera activa y calcula impacto, daño al medidor de Olvido y efectos.",
	},

	ToolEquip = {
		direction = "ClientToServer",
		reliable = true,
		schema = {
			slot = { kind = "int", min = 1, max = 2 },
			tool = enum(Types.ToolIds),
		},
		rateLimit = { burst = 3, perSecond = 1 },
		notes = "Solo dentro de una zona con tag ZonaPueblo; si no, aviso Tool.EquipOnlyInTown.",
	},

	ToolUpgrade = {
		direction = "ClientToServer",
		reliable = true,
		schema = {
			tool = enum(Types.ToolIds),
		},
		rateLimit = { burst = 2, perSecond = 0.5 },
		notes = "El costo (50/150/400) sale de Config, nunca del cliente. "
			.. "Cobro y subida de nivel en una sola mutación del perfil. ECONOMÍA: requiere aprobación.",
	},

	PuzzleSubmit = {
		direction = "ClientToServer",
		reliable = true,
		schema = {
			puzzle = NET_ID,
			step = { kind = "int", min = 1, max = 16 },
			answer = { kind = "array", of = { kind = "int", min = 1, max = 12 }, maxLen = 8 },
		},
		rateLimit = { burst = 4, perSecond = 1 },
		maxDistance = 30,
		anchorField = "puzzle",
		notes = "El servidor tiene la solución y el paso actual del grupo cercano. "
			.. "Fallo → Puzzle.Failed y aparecen Polillas de Papel con la pista (biblia §5). "
			.. "Mismo paso repetido tras resolverse → Rejected, sin recompensa.",
	},

	QuickChat = {
		direction = "ClientToServer",
		reliable = true,
		schema = {
			phrase = { kind = "int", min = 1, max = 6 },
		},
		rateLimit = { burst = 2, perSecond = 0.34 }, -- ~1 frase cada 3 s
		notes = "Sin texto libre (D-009). Se reenvía a jugadores en 60 studs.",
	},

	--------------------------------------------------------------------
	-- Servidor → Cliente (5)
	--------------------------------------------------------------------

	ProfileSync = {
		direction = "ServerToClient",
		reliable = true,
		schema = {
			view = { kind = "opaque", note = "Types.ProfileView completo" },
		},
		notes = "Snapshot completo al entrar y tras cada cambio, con debounce de 0.2 s. "
			.. "El perfil es pequeño: no se mandan deltas por ruta.",
	},

	Notice = {
		direction = "ServerToClient",
		reliable = true,
		schema = {
			key = { kind = "opaque", note = "Types.NoticeKey" },
			args = { kind = "opaque", note = "{ [string]: string | number } con valores ya validados" },
		},
		notes = "El cliente traduce la clave; nunca se manda texto para mostrar tal cual.",
	},

	PuzzleResult = {
		direction = "ServerToClient",
		reliable = true,
		schema = {
			puzzle = NET_ID,
			step = { kind = "int", min = 1, max = 16 },
			result = { kind = "opaque", note = "Types.PuzzleResult" },
		},
		notes = "Va a todos los jugadores del grupo cercano del acertijo.",
	},

	ToolFx = {
		direction = "ServerToClient",
		reliable = false, -- UnreliableRemoteEvent: perder un efecto no importa
		schema = {
			userId = { kind = "opaque", note = "number" },
			tool = { kind = "opaque", note = "Types.ToolId" },
			origin = { kind = "opaque", note = "Vector3" },
			aim = { kind = "opaque", note = "Vector3 unitario" },
			boosted = { kind = "opaque", note = "boolean: resortera activa" },
		},
		notes = "Solo para pintar el efecto en otros clientes; no tiene consecuencias de juego.",
	},

	QuickChatShow = {
		direction = "ServerToClient",
		reliable = true,
		schema = {
			userId = { kind = "opaque", note = "number" },
			phrase = { kind = "int", min = 1, max = 6 },
		},
		notes = "Globo sobre el jugador con la frase fija.",
	},
}

-- Validación del propio registro: falla al cargar si un contrato está incompleto.
for name, c in Contracts do
	if c.direction == "ClientToServer" then
		assert(c.rateLimit, `Contrato {name}: ClientToServer sin rateLimit`)
		for field, f in c.schema do
			assert(f.kind ~= "opaque", `Contrato {name}.{field}: 'opaque' no se permite de cliente a servidor`)
		end
	end
	if c.maxDistance then
		assert(c.anchorField and c.schema[c.anchorField], `Contrato {name}: maxDistance sin anchorField válido`)
	end
end

return table.freeze(Contracts)
