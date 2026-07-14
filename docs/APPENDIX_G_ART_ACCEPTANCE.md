# Appendix G P0 Art Acceptance

This checklist turns Appendix G into runtime-verifiable production rules. Assets that fail a row remain concept references and must not be presented as final animation resources.

## Character Animation

| Actor | Grid | Required groups | Frames per group | Cell size at source |
| --- | --- | --- | --- | --- |
| Yan Wugui | 8 x 6 | idle, run, attack, dodge, hurt, dead | 8 | 192 x 170.67 px |
| Blade spirit | 8 x 4 | idle, run, attack, dead | 8 | 221.75 x 221.75 px |
| Bronze guard | 8 x 4 | idle, run, attack, dead | 8 | 221.75 x 221.75 px |
| Dart thrower | 8 x 4 | idle, run, attack, dead | 8 | 221.75 x 221.75 px |
| Golden armor elite | 7 x 5 | idle, run, attack, hurt, dead | 7 | 226.57 x 198.4 px |
| Golden Armor General | 8 x 6 | idle, run, attack, phase, hurt, dead | 8 | 181 x 181 px |

Every frame must use the same steep top-down camera, right-facing baseline, scale and foot anchor. Runtime may mirror on X, but must not rotate a perspective sprite.

## Combat VFX Sequences

| Batch | Grid | Independent rows | Frames per row |
| --- | --- | --- | --- |
| Weapon actions | 8 x 4, 221.75 px cells | combo 1, combo 2, combo 3, dodge | 8 |
| Impacts | 8 x 4, 221.75 px cells | normal hit, critical hit, shield break, death dissolve | 8 |
| Five elements | 8 x 6, 181 px cells | metal, wood, water, fire, earth, harmony | 8 |
| Duanshui subskills | 8 x 3 | sword wave, blink slash, combo haste | 8 |
| Shuangren subskills | 8 x 3 | ice scar, cold flash, frost armor | 8 |
| Mohong subskills | 8 x 3 | rainbow cut, ink shadow, returning blade | 8 |
| Lieshan subskills | 8 x 3 | mountain cleave, earthquake, iron wall slash | 8 |
| Yinxue subskills | 8 x 3 | blood rage, soul bite slash, blood shield | 8 |
| Progression | 8 x 5 | relic, weapon, low/mid/high pattern activation | 8 |

Each row is one authored temporal effect. A gameplay event selects exactly one sequence row; hit-stop, shake and small procedural ink droplets may accompany it, but static atlas compositing is not the primary visual.

## Appendix G Gates

- Character source cells remain within the documented 128-256 px range.
- Yan Wugui has all six required groups with 6-12 frames each.
- P0 common enemies have 3-4 groups; elite has 4-5; Boss has 5-6.
- P0 uses one monochrome environment set, one UI kit and 64-128 px procedural ink particles.
- Every Yan Wugui weapon subskill has its own eight-frame row; no skill branch substitutes generic dodge/element/death stamps for its primary effect.
- Runtime tests assert all 34 VFX rows, grid metadata and frame bounds.
- Visual QA checks identity consistency, camera, anchors, directional readability, HUD overlap and sequence timing.

## Legacy Status

`assets/characters/atlases/p0_character_atlas.png`, `combat_vfx_atlas.png`, `combat_motion_vfx.png` and `combat_elemental_vfx.png` are retained as concept/style references. Gameplay no longer preloads or composites them.
