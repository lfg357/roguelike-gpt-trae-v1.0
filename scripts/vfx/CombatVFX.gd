extends RefCounted

const ATLAS: Texture2D = preload("res://assets/vfx/atlases/combat_vfx_atlas.png")
const CELL_SIZE := Vector2(512, 512)
const MOTION_ATLAS_SIZE := Vector2(1672, 941)
const MOTION_CELL_SIZE := Vector2(MOTION_ATLAS_SIZE.x / 3.0, MOTION_ATLAS_SIZE.y / 2.0)
const ELEMENTAL_CELL_SIZE := Vector2(512, 512)
const REGIONS := {
	"slash": Rect2(0, 0, 512, 512),
	"hit": Rect2(512, 0, 512, 512),
	"dodge": Rect2(1024, 0, 512, 512),
	"fire": Rect2(0, 512, 512, 512),
	"water": Rect2(512, 512, 512, 512),
	"metal": Rect2(1024, 512, 512, 512),
}
const MOTION_REGIONS := {
	"quick_slash": Rect2(Vector2(0, 0), MOTION_CELL_SIZE),
	"heavy_slash": Rect2(Vector2(MOTION_CELL_SIZE.x, 0), MOTION_CELL_SIZE),
	"crit_hit": Rect2(Vector2(MOTION_CELL_SIZE.x * 2.0, 0), MOTION_CELL_SIZE),
	"shield_break": Rect2(Vector2(0, MOTION_CELL_SIZE.y), MOTION_CELL_SIZE),
	"dash_trail": Rect2(Vector2(MOTION_CELL_SIZE.x, MOTION_CELL_SIZE.y), MOTION_CELL_SIZE),
	"death_ink": Rect2(Vector2(MOTION_CELL_SIZE.x * 2.0, MOTION_CELL_SIZE.y), MOTION_CELL_SIZE),
}
const ELEMENTAL_REGIONS := {
	"metal_ring": Rect2(Vector2(0, 0), ELEMENTAL_CELL_SIZE),
	"wood_burst": Rect2(Vector2(512, 0), ELEMENTAL_CELL_SIZE),
	"ice_burst": Rect2(Vector2(1024, 0), ELEMENTAL_CELL_SIZE),
	"fire_slash": Rect2(Vector2(0, 512), ELEMENTAL_CELL_SIZE),
	"earth_break": Rect2(Vector2(512, 512), ELEMENTAL_CELL_SIZE),
	"harmony": Rect2(Vector2(1024, 512), ELEMENTAL_CELL_SIZE),
}


static func region(kind: String) -> Rect2:
	return REGIONS.get(kind, REGIONS["hit"])


static func motion_region(kind: String) -> Rect2:
	return MOTION_REGIONS.get(kind, MOTION_REGIONS["crit_hit"])


static func elemental_region(kind: String) -> Rect2:
	return ELEMENTAL_REGIONS.get(kind, ELEMENTAL_REGIONS["harmony"])
