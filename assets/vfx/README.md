# Combat VFX Sequences

Runtime effects live in `sequences/`. Generated chroma-key sources live in
`source/sequences/` and are excluded from Godot's resource scan.

| Runtime file | Grid | Independent temporal rows |
| --- | --- | --- |
| `weapon_actions.png` | 8 x 4 | combo 1, combo 2, combo 3, dodge |
| `impact_actions.png` | 8 x 4 | normal hit, critical hit, shield break, death dissolve |
| `element_actions.png` | 8 x 6 | metal, wood, water, fire, earth, five-element harmony |
| `duanshui_subskills.png` | 8 x 3 | sword wave, blink slash, combo haste |
| `shuangren_subskills.png` | 8 x 3 | ice scar, cold flash, frost armor |
| `mohong_subskills.png` | 8 x 3 | rainbow cut, ink shadow, returning blade |
| `lieshan_subskills.png` | 8 x 3 | mountain cleave, earthquake, iron wall slash |
| `yinxue_subskills.png` | 8 x 3 | blood rage, soul bite slash, blood shield |
| `progression_actions.png` | 8 x 5 | relic get, weapon get, low/mid/high pattern activation |

Each row contains eight chronological frames with its own anticipation, peak and
dissipation. A gameplay event selects its primary row through
`scripts/vfx/VFXSequences.gd`; hit response may play at the struck actor, but the
skill itself is not assembled by stacking unrelated static atlas cells.

The older files in `atlases/` are retained only as visual-history references and are
not preloaded or composited by gameplay.
