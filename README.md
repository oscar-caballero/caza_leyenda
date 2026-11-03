# Cazadores de Leyendas

RPG cooperativo en Roblox para niños de 8 a 12 años: los Cazadores recuperan las historias de las leyendas de México antes de que el Olvido las deforme.

- **Biblia del mundo:** [`docs/biblia-del-olvido.md`](docs/biblia-del-olvido.md) (aprobada v1.0)
- **Registro de decisiones:** [`docs/decisiones.md`](docs/decisiones.md)
- **Contratos congelados:** `src/ReplicatedStorage/Shared/Types.luau` y `src/ReplicatedStorage/Shared/Net/Contracts.luau` (D-016)

## Estructura

```
src/ReplicatedStorage/Shared/   Types, Net (contratos) y Config compartidos
src/ServerScriptService/        Services y Bootstrap del servidor
src/StarterPlayer/...           Controllers y UI del cliente
tests/                          Tests (Lune para módulos puros, Jest-Lua en Open Cloud)
docs/                           Biblia, decisiones y documentación
```

## Desarrollo

Herramientas fijadas con Rokit (`rokit.toml`): Rojo, StyLua, selene, luau-lsp y Lune.

```bash
rokit install            # instala las versiones fijadas
rojo serve               # sincroniza con Roblox Studio (plugin de Rojo)
./scripts/check.sh       # StyLua + selene + luau-lsp + tests de Lune (lo mismo que la CI)
```

Ningún PR se mergea con la CI en rojo (D-010).

Cambios a contratos, datos, economía, contenido infantil, chat, assets de IA o publicación requieren aprobación humana (D-010).
