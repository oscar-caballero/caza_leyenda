# Catálogo de assets 3D

Requisito de D-010: cada asset registra herramienta, licencia, prompt, procedencia cultural y aprobación humana.

| Asset | Herramienta | Licencia | Prompt (IA) | Procedencia cultural | Triángulos (presupuesto) | Aprobación humana |
|---|---|---|---|---|---|---|
| Polilla de Papel (`PolillaPapel.fbx`) | Blender 5.2 por código (`assets/src/polilla_papel.py`), sin IA | Propia del proyecto | — | ✏️ Invención del juego (criatura del Olvido, nivel 3). Origami con hoja de cuaderno rayado; sin motivos de ninguna comunidad | 160 (≤400) | Pendiente |

## Cómo se generan

```bash
./assets/build.sh            # todos los modelos
./assets/build.sh polilla_papel
```

Cada script verifica su presupuesto de triángulos (falla si se pasa) y deja:
- `assets/export/<Modelo>.fbx` y `<Modelo>_atlas.png` para importar en Roblox Studio
- `assets/preview/<Modelo>.png`, una vista previa para revisión

## Cómo se importan en Studio

1. **Archivo → Importar 3D** y elige `assets/export/<Modelo>.fbx`. Cada objeto de Blender queda como un MeshPart.
2. Revisa que la textura del atlas se haya aplicado; si no, asigna `<Modelo>_atlas.png` como `TextureID` de cada MeshPart.
3. Guarda el modelo importado con clic derecho → **Save to File…** en `assets/roblox/<Modelo>.rbxm`. Rojo lo sincroniza y el código lo usa en lugar del cubo provisional.

Reglas: assets de IA solo como blockout y siempre pasan por Blender (D-010). Nada de papel picado ni motivos de comunidades concretas (biblia §10, D-019).
