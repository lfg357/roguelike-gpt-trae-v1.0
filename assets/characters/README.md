# P0 Character Sequences

Runtime character art lives in `animated/` and follows Appendix G's 128-256 px
source-cell rule:

| File | Grid | Actions |
| --- | --- | --- |
| `player/yan_wugui_actions.png` | 8 x 6 | idle, run, attack, dodge, hurt, dead |
| `enemies/blade_actions.png` | 8 x 4 | idle, run, attack, dead |
| `enemies/guard_actions.png` | 8 x 4 | idle, run, attack, dead |
| `enemies/dart_actions.png` | 8 x 4 | idle, run, attack, dead |
| `enemies/elite_actions.png` | 7 x 5 | idle, run, attack, hurt, dead |
| `enemies/boss_actions.png` | 8 x 6 | idle, run, attack, phase, hurt, dead |

Every row is an authored temporal action, not a set of alternate static portraits.
The sprites use a right-facing baseline. Runtime rendering mirrors them on X instead
of rotating the figures, preserving their steep top-down perspective.

`scripts/art/CharacterSequences.gd` owns grid metadata and source regions. The old
`atlases/p0_character_atlas.png` remains a concept reference and is not preloaded by
gameplay. Generated chroma-key sources stay under `source/` for provenance and are
excluded from Godot imports.
