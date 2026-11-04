# Registro de decisiones — Cazadores de Leyendas

Decisiones tomadas sobre la propuesta `cazadores_de_leyendas_propuesta_expertos.md` (v0.2).
Fuente: sesión del Estudio Roblox del 2026-10-30 (reporte: https://claude.ai/artifact/Sceho2pkuKvCJn2sxxVGKm) y decisiones del responsable del proyecto.

---

## D-001 · Veredicto del MVP (2026-10-30)

**Decisión:** el proyecto se aprueba con **recorte obligatorio**: un MVP que sea una vertical slice pulida y segura, no el alcance completo de la sección 15.
**Motivo:** el MVP original requiere unas 16–18 semanas; el plan disponible es de 12 semanas con 1 desarrollador y agentes de IA.

## D-002 · Reglas de mundo: el Olvido

- Una leyenda existe mientras se cuenta.
- El desequilibrio viene del **Olvido**: las criaturas se deforman cuando se pierde su historia.
- Los juguetes funcionan porque son juego y memoria (ritmo, giro, sonido), no armas.
- "Cazar" significa **recuperar la historia verdadera**, y el bestiario es la mecánica de la trama.
- El hilo común entre regiones es el Olvido, no el Mictlán. Cada región cierra su arco con su propia tradición.

## D-003 · Niveles culturales de criaturas

| Nivel | Tipo | Trato en el juego |
|---|---|---|
| 1 | Creencia vigente (nahual, aluxes, chaneque) | Nunca son enemigas: solo ayuda o mediación |
| 2 | Leyenda pública mestiza (Llorona, Charro Negro) | Pueden ser antagonistas en un misterio o desafío |
| 3 | Criatura original | Libres para el combate |

- Cada dato del bestiario lleva una etiqueta con icono: pergamino (documentado), mapa (variante regional) o lápiz (invención del juego). La fuente queda visible para los padres.
- La Llorona y el Charro Negro se diseñan desde cero a partir de la tradición oral, sin parecido con versiones con dueño (Ánima Estudios, Warner).
- Prendas y motivos: solo patrones originales inspirados en técnicas, nunca diseños de una comunidad concreta.
- La consulta a comunidades es requisito para las regiones posteriores al MVP.

## D-004 · Contenido del MVP

**Herramientas (2 ranuras equipadas, cambio gratis en el pueblo):** honda (proyectil; absorbe a la resortera), yo-yo (extender y regresar), matraca (área). Cada efecto se distingue por color y forma.

**Criaturas:**
- Chaneque: guía NPC (nivel 1), solo encuentros de ayuda.
- Llorona: misterio de ayuda (nivel 2), sin infanticidio.
- 2 criaturas originales (nivel 3): las únicas con combate.
- Jefe: Charro Negro (nivel 2), **desafío de destreza**, no apuesta ni pacto.

**Entra:** ToolBase, CreatureBase con **medidor de Olvido** (no barra de vida), QuestService tipado (máx. 2 minijuegos a medida), ProfileStore, módulo Net con rate limit por Remote, bestiario con etiquetas, tutorial de unos 3 min, chat rápido de 6 frases fijas.

**Se aplaza:** atributos, especializaciones, Esencias, ropa en capas, nahual, aluxes, huipil, Mictlán, Places adicionales.

## D-005 · Encuentros sin combate: acertijos (decisión del responsable, 2026-10-30)

**Decisión:** las criaturas de nivel 1 y 2 se resuelven mediante **acertijos** que usan las herramientas y las pistas del entorno (en lugar de ofrendas o ritmo).
**Motivo:** encajan con el pilar de exploración y aprendizaje y reutilizan los tags de CollectionService ("Activable", "Sonoro", "Giratorio").
**Pendiente de diseño:** los acertijos deben tener riesgo real (fallar tiene consecuencia y no solo se reintenta) para que el ~40 % de acción no quede vacío. Como máximo 1 acertijo cooperativo con roles por capítulo, siempre resoluble en solitario.

## D-006 · Texto en pantalla (decisión del responsable, 2026-10-30)

**Decisión:** máximo **12 palabras por globo** de diálogo, en 2 líneas, con "toca para seguir" y voz opcional. Las instrucciones del tutorial llevan 8 palabras como máximo.
**Motivo:** el público es de 8 a 12 años y juega en celular.

## D-007 · Sistemas, progresión y economía

- Una sola moneda: **Semillas**. Los Fragmentos son fichas de desbloqueo y no se pueden intercambiar. No hay comercio entre jugadores.
- Mejoras de herramienta en 3 niveles: 50 / 150 / 400 Semillas (1,800 en total). Antes del jefe solo alcanza para dejar al máximo una herramienta.
- Nivel máximo 6, curva de XP 100·n^1.5 (unos 2,800 XP en total; validar con telemetría). Un MVP de unas 2 h.
- Daño de las herramientas dentro de un ±10 % entre ellas. Cada criatura tiene una herramienta preferida (+25 % de eficacia) y una alternativa viable.
- Ropa con **transfiguración**: el slot de apariencia va separado del de efecto. Los efectos solo aplican por entorno, con un tope de ±15 %, y se muestran con un icono de entorno y una flecha verde o roja.

## D-008 · Respuestas a la sección 23

| Pregunta | Opción | Detalle |
|---|---|---|
| 23.1 Estilo | E | Cartoon robusto (A) con folclore en paleta y texturas pintadas originales (C) |
| 23.2 Cacería | C | Solo las originales se combaten; las mestizas se resuelven como misterio o desafío; las vigentes nunca se derrotan |
| 23.3 Folclore | C | Leyendas documentadas y criaturas originales, con etiquetas visibles |
| 23.4 Mundo | C | Pueblo central que cambia según el perfil (se pinta en el cliente); un solo Place con StreamingEnabled |
| 23.5 Herramientas | C | 2 ranuras equipadas |
| 23.6 Vestimenta | C | Con transfiguración |
| 23.7 Multijugador | B | Cooperativo; el escalado cuenta solo el grupo cercano, con tope n=4 (×2.5) |
| 23.8 Época | E | Pueblo atemporal hasta mediados del s. XX (radio, faroles, sin celulares); cada región declara su tradición |

## D-009 · Arquitectura y seguridad

- ProfileStore con session lock; recompensas idempotentes con `RewardId` en `ClaimedRewards`; tope de inventario.
- Un único módulo `Net` con contratos tipados (`--!strict`): esquema, rate limit por Remote y validación de distancia. Un Remote no registrado se rechaza.
- Services y Controllers propios con un Bootstrap, sin Knit.
- Tolerancia de lag con tope: rebobinado de 250 ms como máximo, más distancia y cooldown en el servidor. La predicción en el cliente es solo visual.
- 6–8 jugadores por servidor. "Rumor del día" calculado con `os.time` del servidor.
- Chat de texto libre apagado (TextChatService) y sin ningún texto libre generado por jugadores.
- Se guarda: progreso, inventario, colecciones y equipamiento. No se guardan posiciones ni el estado de los encuentros.

## D-010 · Herramientas, CI y trabajo con agentes

- CI en cada PR: selene, StyLua, luau-lsp analyze y Jest-Lua (vía Open Cloud Luau Execution) con Lune para módulos puros. No se hace merge con la suite en rojo.
- Trunk-based con PRs cortos, un sistema por rama/agente, y los contratos de `Shared/Types` y `Net` congelados antes de programar.
- Assets de IA (Meshy/Tripo): solo como blockout. Todo pasa por Blender (retopología, UV, retexturizado, rig). Cada asset queda en un catálogo con herramienta, licencia, prompt, procedencia cultural y aprobación humana. Plan comercial pagado.
- Presupuestos: personaje/NPC 4–6k triángulos, criatura 3–5k, jefe 8–12k, herramienta 0.5–1.5k. Atlas de 1024² por región. SurfaceAppearance solo en el jefe.
- **Requieren aprobación humana:** contratos de red, esquema y migraciones de datos, economía y recompensas, contenido infantil, chat, integración de assets de IA y publicación.

## D-011 · Criterios de aceptación medibles (reemplazan la 15.3)

- ≥30 FPS sostenidos en un Android de 3 GB, sin bajar de 25 durante el 90 % del tiempo.
- Carga inicial de menos de 20 s.
- Heartbeat del servidor ≥55 con 8 jugadores.
- 0 pérdidas de perfil en 500 ciclos de entrar/salir/desconexión forzada.
- Tope de memoria del cliente: se fija al medir la vertical slice (semana 6).
- Uso por herramienta entre 15 % y 65 %; fuera de ese rango se dispara una alerta.
- ≥80 % de los niños completa el tutorial sin ayuda (pruebas con 6–8 niños, con consentimiento de sus responsables).
- Caso de prueba "jugar en silencio": nada depende solo del sonido ni solo del color.

## D-012 · Calendario

| Semanas | Trabajo |
|---|---|
| 1 | Biblia de mundo, guía de estilo y tabla cultural; contratos Net/Types |
| 2–3 | ToolBase (honda + yo-yo), CreatureBase, ProfileStore, CI |
| 4–6 | Vertical slice: tutorial + 1 original + 3 misiones; prueba con niños |
| 7–10 | Matraca, Llorona, segunda original, Charro, resto de misiones |
| 11–12 | QA en móvil y prueba con niños |

QA continuo (unos 20 % del esfuerzo) desde la semana 2.

## D-013 · Pendientes de la biblia del Olvido (decisión del responsable, 2026-11-02)

- **Origen del Olvido:** las historias se cuentan mal, desde un punto de vista malvado. Al avanzar, el jugador descubre la historia verdadera. Cada leyenda tiene en el bestiario una versión "que se cuenta" y una "verdadera".
- **Resortera:** power-up momentáneo que convierte la honda en disparo rápido durante unos segundos. No ocupa ranura.
- **Llorona:** se lamenta por sus hijos. La versión contada la vuelve malvada; en la verdadera, ella quería salvarlos.
- **Criaturas del Olvido:** "Polillas de Papel" (enemigo común) y "El Rumor" (enemigo fuerte, antes "El Borrón"; está hecho de la versión torcida que todos repiten).
- **Región 1:** Pueblo de los Faroles.
- **Orden:** se mantiene "Cazadores de Leyendas", con el lema "La verdad se oculta".
- **Matraca:** se usa sin restricción extra.
- **Riesgo de los acertijos (cierra el pendiente de D-005):** al fallar, las Polillas de Papel se comen una pista y hay que recuperarla en un combate corto antes de reintentar.
- **Bestiario:** la biblia incorpora las etiquetas de fuente de D-003 (pergamino, mapa y lápiz).
- **Extensión de la biblia:** se acepta que ocupe más de una página.
- **Llorona y Charro Negro:** su revisión cultural pasa al Estudio Roblox antes de la aprobación final.
- **Chaneque:** se aprueba su uso como creencia viva de nivel 1.

## D-014 · Revisión cultural de la Llorona y el Charro Negro (Investigador Cultural + responsable, 2026-11-02)

**Dictamen:** las tres adaptaciones se aprueban con cambios; los cambios fueron aceptados por el responsable.
- **Tres capas en el bestiario:** "Lo que cuenta la tradición" (📜/🗺️), "El rumor del Olvido" (✏️) e "Historia recuperada" (✏️, con 📜 donde tenga base). En las etiquetas se usa "recuperada", nunca "verdadera". Lo que se desmiente es la caricatura del Olvido, nunca la tradición.
- **Llorona:** su base es el sexto presagio de Sahagún (Libro XII). La muerte de los hijos queda ambigua, el cierre es simbólico y el bestiario lleva una nota para padres.
- **Charro Negro:** su historia recuperada es la de un héroe que fingió ser malvado para salvar a un pueblo de unos villanos (inventados). Se conserva la **tentación** de la tradición: durante el desafío ofrece atajos y monedas, y rechazarlos es parte de ganar. Traje de charro respetuoso (UNESCO 2016) y sin parecido con Ánima (2018).

## D-015 · Aprobación de la biblia del Olvido (decisión del responsable, 2026-11-02)

**Decisión:** se aprueba `biblia-del-olvido.md` v1.0. Queda abierto solo un [VERIFICAR] menor (la cita exacta de Sahagún), que no bloquea.
**Efecto:** se levanta el bloqueo de D-012. Los agentes ya pueden escribir código y generar assets siguiendo la biblia y las reglas de D-010 (aprobación humana para contratos de red, datos, economía, contenido infantil, chat, assets de IA y publicación).

## D-016 · Contratos `Shared/Types` y `Net` congelados (decisión del responsable, 2026-11-03)

**Decisión:** se aprueban y congelan `src/ReplicatedStorage/Shared/Types.luau` y `src/ReplicatedStorage/Shared/Net/Contracts.luau` (v1.0).
- 10 Remotes, solo RemoteEvent/UnreliableRemoteEvent, sin RemoteFunction. Cliente → servidor: `ToolUse`, `ToolEquip`, `ToolUpgrade`, `PuzzleSubmit` y `QuickChat`, cada uno con esquema y rate limit. Servidor → cliente: `ProfileSync`, `Notice`, `PuzzleResult`, `ToolFx` y `QuickChatShow`.
- Interacciones por ProximityPrompt en el servidor, resortera detectada en el servidor y medidor de Olvido por atributos replicados.
- El cliente nunca envía daño, Semillas, recompensas, posición ni el resultado de un acertijo.
- Perfil `SCHEMA_VERSION = 1`. Cualquier cambio sube la versión y lleva su migración.
- El ajuste de tipos que salga en `luau-lsp` (sin ejecutar aún) se permite si no cambia el contrato.

## D-017 · Persistencia: DataService sobre ProfileStore (decisión del responsable, 2026-11-03)

- **Librería:** ProfileStore de MadStudio copiada en `src/ServerScriptService/Vendor/`, fijada al commit `45c9847` (Apache-2.0). Sin Wally.
- **Almacén:** `PlayerData`, llave `Player_<UserId>`. En Studio se usa `ProfileStore.Mock`.
- **Carga:** primero se revisa la versión (un perfil de una versión más nueva expulsa al jugador **sin modificarlo**). Después migraciones `[n] → n+1`, `Reconcile()` y sanitización de topes e ids.
- **Mutaciones:** solo `DataService.grantReward` (idempotente por `RewardId`), `spendSeeds` (cobro y efecto atómicos) y `update`. Se aplican sobre una copia y se escriben solo si no fallan. Tras cada una, `ProfileSync` con debounce de 0.2 s.
- **Fallos:** si no carga en 15 s o la sesión pasa a otro servidor, se expulsa al jugador con un mensaje fijo. Nunca se juega con un perfil temporal.
- **Pendiente:** la prueba de D-011 (500 ciclos sin pérdida) requiere Open Cloud y el place de pruebas.

## D-018 · Criaturas del Olvido y sus recompensas (decisión del responsable, 2026-11-03)

- **CreatureBase aprobado y probado en Studio:** medidor de Olvido, movimiento en el servidor, freno del yo-yo, escalado cooperativo D-008 y rebobinado D-009 de 250 ms con línea de vista.
- **Economía aprobada** (`Config/Creatures.luau`):

| Criatura | Olvido | XP por disiparla (a quien aportó ≥10 %) | Semillas (solo la 1.ª vez, `defeat:<NetId>`) | Reaparece |
|---|---|---|---|---|
| Polilla de Papel | 30 | 5 | 0 | 8 s |
| Rumor | 400 | 60 | 40 | 30 s |

- **Pendiente de diseño:** daño de las criaturas al jugador (no hay vida del jugador definida) y el combo del Rumor (marcar con la honda y traer sus pedazos con el yo-yo). Vigilar con telemetría el farmeo de XP con las polillas.

## Siguiente paso

Semana 2 de D-012 terminada (repo + CI, `Net`, DataService, ToolBase y CreatureBase). Siguiente, semanas 4–6: **vertical slice** (tutorial de ~3 min, 1 criatura original y 3 misiones con QuestService) y prueba con niños.
