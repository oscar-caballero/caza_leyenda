# Catálogo de assets 3D

Requisito de D-010: cada asset registra herramienta, licencia, prompt, procedencia cultural y aprobación humana.

| Asset | Herramienta | Licencia | Prompt (IA) | Procedencia cultural | Triángulos (presupuesto) | Aprobación humana |
|---|---|---|---|---|---|---|
| Polilla de Papel (`PolillaPapel.fbx`) | Blender 5.2 por código (`assets/src/polilla_papel.py`), sin IA | Propia del proyecto | — | ✏️ Invención del juego (criatura del Olvido, nivel 3). Origami con hoja de cuaderno rayado; sin motivos de ninguna comunidad | 160 (≤400) | ✅ Aprobada por el responsable (2026-11-03) |
| Honda (`Honda.fbx`) | Blender 5.2 por código (`assets/src/honda.py`), sin IA | Propia del proyecto | — | 📜 Juguete tradicional (honda de cordeles con cuna). Tejido de franjas **originales** naranja y crema; no reproduce textiles de ninguna comunidad | 460 (≤1,500) | ✅ Aprobada por el responsable (2026-11-03) |
| Yo-yo (`Yoyo.fbx`) | Blender 5.2 por código (`assets/src/yoyo.py`), sin IA | Propia del proyecto | — | 📜 Juguete tradicional de madera torneada. Pintura con franjas originales en cian (color del efecto, D-004) | 516 (≤1,500) | ✅ Aprobada por el responsable (2026-11-03) |
| Resortera (`Resortera.fbx`) | Blender 5.2 por código (`assets/src/resortera.py`), sin IA | Propia del proyecto | — | 📜 Juguete tradicional (horqueta, ligas y bolsa). Madera dorada por ser el power-up (D-013) | 232 (≤1,500) | ✅ Aprobada por el responsable (2026-11-03) |
| Farol (`Farol.fbx`) | Blender 5.2 por código (`assets/src/farol.py`), sin IA | Propia del proyecto | — | ✏️ Farol genérico de hierro de mediados del s. XX ("pueblo de los abuelos", biblia §7). Piezas: Poste y Vidrio (el código enciende el vidrio) | 298 (≤1,500 para props repetidos) | ✅ Aprobada por el responsable (2026-11-03) |
| Kiosco (`Kiosco.fbx`) | Blender 5.2 por código (`assets/src/kiosco.py`), sin IA | Propia del proyecto | — | 🗺️ Kiosco octagonal genérico de plaza mexicana; no copia el de ningún pueblo real. Hierro verde y techo ocre de la paleta de la región. Mismas medidas que el greybox | 1,172 (≤5,000 para landmark) | ✅ Aprobada por el responsable (2026-11-03) |
| El Rumor (`Rumor.fbx`) | Blender 5.2 por código (`assets/src/rumor.py`), sin IA | Propia del proyecto | — | ✏️ Invención del juego (criatura del Olvido, nivel 3). Collage de **papel de periódico inventado** (sin texto real) y juguetes rotos deslavados; **sin papel picado** (artesanía viva, D-019). Cucuruchos como bocas, sin rasgos de terror | 2,028 (≤5,000) | Pendiente |

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
