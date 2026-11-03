#!/usr/bin/env bash
# Corre las mismas verificaciones que la CI (D-010). Uso: ./scripts/check.sh
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"

# Definiciones de Roblox fijadas a la versión de luau-lsp de rokit.toml
LSP_VERSION=$(sed -n 's/^luau-lsp = "JohnnyMorganz\/luau-lsp@\(.*\)"/\1/p' rokit.toml)
if [ ! -f globalTypes.d.luau ] || [ "$(cat .globalTypes.version 2>/dev/null)" != "$LSP_VERSION" ]; then
	curl -sSfL "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/${LSP_VERSION}/scripts/globalTypes.d.luau" -o globalTypes.d.luau
	echo "$LSP_VERSION" > .globalTypes.version
fi
[ -f roblox.yml ] || selene generate-roblox-std >/dev/null

echo "== StyLua";   stylua --check src tests
echo "== selene";   selene src
echo "== sourcemap"; rojo sourcemap default.project.json -o sourcemap.json
echo "== luau-lsp"; luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json \
	--definitions=@roblox=globalTypes.d.luau src
if compgen -G "tests/unit/*.luau" >/dev/null; then
	echo "== Lune (unit)"
	for t in tests/unit/*.luau; do lune run "$t"; done
fi
echo "OK: todo en verde"
