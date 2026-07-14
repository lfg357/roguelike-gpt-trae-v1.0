# Art Resource Audit

This file records the intended use of the user-provided archives in `art-resources/`.
Assets are not imported merely because they are available; visual language, camera
angle, resolution and licensing notes must all fit the current game.

| Archive group | Decision | Reason / possible use |
| --- | --- | --- |
| Effect and FX Pixel / Super Pixel Effects / Free Smoke FX | Reference only | Useful timing and frame-count references, but the pixel edge language conflicts with the high-resolution ink rendering. |
| samurai / Adventurer / FallenOrder / Tiny RPG / Pixel Crawler | Silhouette reference only | Their direct pixel assets do not match, but the slim swordsman, broad shield unit, narrow ranged unit and heavy boss mass informed the new project-owned P0 silhouettes. |
| Raven Fantasy Icons | Hold for later icon study | Large library, but direct use would introduce a separate pixel-art UI language. Review individual 64px icons only when relic icon production begins. |
| UIBundleFree | Reference only | Wood-and-metal fantasy panels conflict with the restrained dark ink UI kit. |
| Producto tilesets | Do not use in current build | Pixel samurai environments do not match the room rendering scale or ink materials. |
| Kenney interface / sci-fi audio | Candidate, not imported | CC0-style utility sounds may supply a few UI clicks or metal impacts after an audio listening pass. Avoid obviously electronic sounds. |
| RPG Sound Pack / Owlish | Candidate, not imported | Sword swings, cloth and footsteps may be useful, but each sound must be auditioned and its included license checked before runtime import. |

## Runtime Selection

The current P0 build uses fifteen project-owned transparent action sheets:

- Six character sheets: Yan Wugui, three common enemies, the elite and the teaching boss.
- `weapon_actions.png`: three attack timings plus dodge, each as an independent eight-frame row.
- `impact_actions.png`: hit, critical hit, shield break and death, each as an independent eight-frame row.
- `element_actions.png`: metal, wood, water, fire, earth and harmony, each as an independent eight-frame row.
- Five weapon-specific sheets: all 15 Yan Wugui subskills have one independent eight-frame row.
- `progression_actions.png`: relic/weapon acquisition and three tiers of pattern activation.

Generated chroma-key sources are retained under `assets/vfx/source/` and
`assets/characters/source/`; only transparent runtime sequences are referenced by gameplay code.
The former static atlases remain in `atlases/` as concept references and are not
preloaded by `Main.gd`.

## Generated Asset Provenance

- Generator: built-in image generation mode.
- Style prompt set: high-resolution Chinese ink brush, ivory/black base, restrained gold and elemental accents, strong game-readable silhouettes, flat green chroma background, no text or UI.
- Character prompt set: separate right-facing steep top-down action sheets with stable identity, scale and foot anchor for every P0 actor.
- VFX prompt set: separate chronological batches for weapon motion, impact response and six elemental effects; no text, UI or unrelated imagery.
