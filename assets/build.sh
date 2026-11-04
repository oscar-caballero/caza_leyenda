#!/usr/bin/env bash
# Genera los modelos 3D con Blender sin interfaz. Uso: ./assets/build.sh [nombre_script ...]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BLENDER=(flatpak run org.blender.Blender)
command -v blender >/dev/null 2>&1 && BLENDER=(blender)

scripts=("$@")
if [ ${#scripts[@]} -eq 0 ]; then
	for f in "$ROOT"/assets/src/*.py; do
		name="$(basename "$f" .py)"
		[ "$name" = "common" ] || scripts+=("$name")
	done
fi

for s in "${scripts[@]}"; do
	echo "== $s"
	"${BLENDER[@]}" -b --factory-startup -P "$ROOT/assets/src/$s.py" 2>&1 \
		| grep -E "^\[|Error|Traceback" || true
done
