extends RefCounted

const ATLAS: Texture2D = preload("res://assets/characters/atlases/p0_character_atlas.png")
const CELL_SIZE := Vector2(512, 512)
const REGIONS := {
	"player": Rect2(Vector2(0, 0), CELL_SIZE),
	"blade": Rect2(Vector2(512, 0), CELL_SIZE),
	"guard": Rect2(Vector2(1024, 0), CELL_SIZE),
	"dart": Rect2(Vector2(0, 512), CELL_SIZE),
	"elite": Rect2(Vector2(512, 512), CELL_SIZE),
	"boss": Rect2(Vector2(1024, 512), CELL_SIZE),
}
const DRAW_SIZES := {
	"player": Vector2(132, 132),
	"blade": Vector2(102, 102),
	"guard": Vector2(114, 114),
	"dart": Vector2(104, 104),
	"elite": Vector2(132, 132),
	"boss": Vector2(168, 168),
}


static func region(kind: String) -> Rect2:
	return REGIONS.get(kind, REGIONS["blade"])


static func draw_size(kind: String) -> Vector2:
	return DRAW_SIZES.get(kind, DRAW_SIZES["blade"])
