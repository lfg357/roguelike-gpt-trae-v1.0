extends RefCounted

const PLAYER: Texture2D = preload("res://assets/characters/animated/player/yan_wugui_actions.png")
const BLADE: Texture2D = preload("res://assets/characters/animated/enemies/blade_actions.png")
const GUARD: Texture2D = preload("res://assets/characters/animated/enemies/guard_actions.png")
const DART: Texture2D = preload("res://assets/characters/animated/enemies/dart_actions.png")
const ELITE: Texture2D = preload("res://assets/characters/animated/enemies/elite_actions.png")
const BOSS: Texture2D = preload("res://assets/characters/animated/enemies/boss_actions.png")

const SPECS := {
	"player": {
		"texture": PLAYER, "atlas_size": Vector2(1536, 1024), "columns": 8, "rows": 6,
		"actions": {"idle": 0, "run": 1, "attack": 2, "dodge": 3, "hurt": 4, "dead": 5},
		"draw_size": Vector2(124, 112), "padding": 2,
	},
	"blade": {
		"texture": BLADE, "atlas_size": Vector2(1774, 887), "columns": 8, "rows": 4,
		"actions": {"idle": 0, "run": 1, "attack": 2, "dead": 3},
		"draw_size": Vector2(92, 92), "padding": 2,
	},
	"guard": {
		"texture": GUARD, "atlas_size": Vector2(1774, 887), "columns": 8, "rows": 4,
		"actions": {"idle": 0, "run": 1, "attack": 2, "dead": 3},
		"draw_size": Vector2(108, 108), "padding": 2,
	},
	"dart": {
		"texture": DART, "atlas_size": Vector2(1774, 887), "columns": 8, "rows": 4,
		"actions": {"idle": 0, "run": 1, "attack": 2, "dead": 3},
		"draw_size": Vector2(96, 96), "padding": 2,
	},
	"elite": {
		"texture": ELITE, "atlas_size": Vector2(1586, 992), "columns": 7, "rows": 5,
		"actions": {"idle": 0, "run": 1, "attack": 2, "hurt": 3, "dead": 4},
		"draw_size": Vector2(124, 110), "padding_x": 18, "padding_y": 3,
	},
	"boss": {
		"texture": BOSS, "atlas_size": Vector2(1448, 1086), "columns": 8, "rows": 6,
		"actions": {"idle": 0, "run": 1, "attack": 2, "phase": 3, "hurt": 4, "dead": 5},
		"draw_size": Vector2(154, 154), "padding": 3,
	},
}

const BASE_ANCHORS := {
	"player": {"idle": Vector2(0.58, 0.83), "run": Vector2(0.57, 0.88), "attack": Vector2(0.47, 0.72), "dodge": Vector2(0.43, 0.74), "hurt": Vector2(0.45, 0.74), "dead": Vector2(0.47, 0.74)},
	"blade": {"idle": Vector2(0.43, 0.78), "run": Vector2(0.49, 0.84), "attack": Vector2(0.43, 0.78), "dead": Vector2(0.49, 0.82)},
	"guard": {"idle": Vector2(0.42, 0.77), "run": Vector2(0.50, 0.84), "attack": Vector2(0.50, 0.82), "dead": Vector2(0.50, 0.84)},
	"dart": {"idle": Vector2(0.46, 0.80), "run": Vector2(0.47, 0.84), "attack": Vector2(0.40, 0.80), "dead": Vector2(0.50, 0.84)},
	"elite": {"idle": Vector2(0.39, 0.84), "run": Vector2(0.43, 0.86), "attack": Vector2(0.46, 0.86), "hurt": Vector2(0.43, 0.84), "dead": Vector2(0.47, 0.86)},
	"boss": {"idle": Vector2(0.49, 0.81), "run": Vector2(0.50, 0.85), "attack": Vector2(0.49, 0.84), "phase": Vector2(0.48, 0.84), "hurt": Vector2(0.46, 0.83), "dead": Vector2(0.48, 0.85)},
}

# Tracks compensate the most visible source-frame drift without blending two bodies.
const ANCHOR_TRACKS := {
	"player": {
		"idle": [Vector2(0.57, 0.83), Vector2(0.58, 0.82), Vector2(0.60, 0.83), Vector2(0.60, 0.82), Vector2(0.58, 0.82), Vector2(0.58, 0.82), Vector2(0.57, 0.82), Vector2(0.55, 0.82)],
		"run": [Vector2(0.54, 0.87), Vector2(0.57, 0.88), Vector2(0.59, 0.87), Vector2(0.59, 0.87), Vector2(0.58, 0.87), Vector2(0.57, 0.87), Vector2(0.55, 0.87), Vector2(0.53, 0.88)],
		"attack": [Vector2(0.45, 0.72), Vector2(0.46, 0.72), Vector2(0.47, 0.72), Vector2(0.49, 0.72), Vector2(0.50, 0.72), Vector2(0.49, 0.72), Vector2(0.47, 0.72), Vector2(0.45, 0.72)],
	},
	"elite": {
		"idle": [Vector2(0.357, 0.84), Vector2(0.357, 0.84), Vector2(0.357, 0.84), Vector2(0.357, 0.84), Vector2(0.357, 0.84), Vector2(0.357, 0.84), Vector2(0.357, 0.84)],
		"run": [Vector2(0.539, 0.86), Vector2(0.614, 0.86), Vector2(0.356, 0.86), Vector2(0.356, 0.86), Vector2(0.398, 0.86), Vector2(0.357, 0.86), Vector2(0.436, 0.86)],
		"attack": [Vector2(0.559, 0.86), Vector2(0.359, 0.86), Vector2(0.356, 0.86), Vector2(0.405, 0.86), Vector2(0.360, 0.86), Vector2(0.358, 0.86), Vector2(0.480, 0.86)],
		"hurt": [Vector2(0.430, 0.84), Vector2(0.393, 0.84), Vector2(0.360, 0.84), Vector2(0.360, 0.84), Vector2(0.367, 0.84), Vector2(0.398, 0.84), Vector2(0.357, 0.84)],
		"dead": [Vector2(0.397, 0.86), Vector2(0.380, 0.86), Vector2(0.447, 0.86), Vector2(0.643, 0.86), Vector2(0.644, 0.86), Vector2(0.572, 0.86), Vector2(0.625, 0.86)],
	},
}

# The elite source sheet was laid out with irregular horizontal spacing. These
# authored frame bounds isolate each complete pose without cropping a neighbour.
const ELITE_X_REGIONS := {
	"idle": [Vector2(35, 206), Vector2(241, 419), Vector2(452, 629), Vector2(666, 834), Vector2(864, 1029), Vector2(1072, 1236), Vector2(1276, 1442)],
	"run": [Vector2(47, 240), Vector2(254, 438), Vector2(476, 661), Vector2(674, 864), Vector2(879, 1065), Vector2(1085, 1263), Vector2(1284, 1465)],
	"attack": [Vector2(49, 176), Vector2(259, 386), Vector2(476, 664), Vector2(670, 833), Vector2(899, 1022), Vector2(1103, 1251), Vector2(1289, 1468)],
	"hurt": [Vector2(42, 156), Vector2(259, 366), Vector2(480, 597), Vector2(681, 796), Vector2(912, 1021), Vector2(1113, 1226), Vector2(1314, 1478)],
	"dead": [Vector2(40, 166), Vector2(245, 374), Vector2(439, 562), Vector2(646, 816), Vector2(860, 1050), Vector2(1083, 1277), Vector2(1307, 1523)],
}


static func texture(kind: String) -> Texture2D:
	return SPECS.get(kind, SPECS["blade"])["texture"]


static func frame_count(kind: String) -> int:
	return int(SPECS.get(kind, SPECS["blade"])["columns"])


static func action_count(kind: String) -> int:
	return int(SPECS.get(kind, SPECS["blade"])["rows"])


static func has_action(kind: String, action: String) -> bool:
	return SPECS.get(kind, SPECS["blade"])["actions"].has(action)


static func region(kind: String, action: String, frame: int) -> Rect2:
	var spec: Dictionary = SPECS.get(kind, SPECS["blade"])
	var columns: int = int(spec["columns"])
	var rows: int = int(spec["rows"])
	var row: int = int(spec["actions"].get(action, spec["actions"]["idle"]))
	var safe_frame := clampi(frame, 0, columns - 1)
	var atlas_size: Vector2 = spec["atlas_size"]
	if kind == "elite":
		var ranges: Array = ELITE_X_REGIONS.get(action, ELITE_X_REGIONS["idle"])
		var x_range: Vector2 = ranges[safe_frame]
		var custom_y0 := roundi(row * atlas_size.y / rows)
		var custom_y1 := roundi((row + 1) * atlas_size.y / rows)
		return Rect2(x_range.x, custom_y0, x_range.y - x_range.x, custom_y1 - custom_y0)
	var x0 := roundi(safe_frame * atlas_size.x / columns)
	var x1 := roundi((safe_frame + 1) * atlas_size.x / columns)
	var y0 := roundi(row * atlas_size.y / rows)
	var y1 := roundi((row + 1) * atlas_size.y / rows)
	var padding_x: int = int(spec.get("padding_x", spec.get("padding", 2)))
	var padding_y: int = int(spec.get("padding_y", spec.get("padding", 2)))
	return Rect2(x0 + padding_x, y0 + padding_y, max(1, x1 - x0 - padding_x * 2), max(1, y1 - y0 - padding_y * 2))


static func draw_size(kind: String) -> Vector2:
	return SPECS.get(kind, SPECS["blade"])["draw_size"]


static func frame_draw_size(kind: String, action: String, frame: int) -> Vector2:
	if kind == "elite":
		return region(kind, action, frame).size * Vector2(0.65, 0.556)
	return draw_size(kind)


static func anchor(kind: String, action: String, frame: int) -> Vector2:
	var kind_tracks: Dictionary = ANCHOR_TRACKS.get(kind, {})
	var source_anchor: Vector2
	if kind_tracks.has(action):
		var track: Array = kind_tracks[action]
		source_anchor = track[clampi(frame, 0, track.size() - 1)]
	else:
		var kind_anchors: Dictionary = BASE_ANCHORS.get(kind, BASE_ANCHORS["blade"])
		source_anchor = kind_anchors.get(action, kind_anchors.get("idle", Vector2(0.5, 0.82)))
	if kind == "elite":
		return source_anchor
	var source_cell := _source_cell(kind, action, frame)
	var cropped := region(kind, action, frame)
	var source_point := source_cell.position + source_anchor * source_cell.size
	return (source_point - cropped.position) / cropped.size


static func atlas_matches_texture(kind: String) -> bool:
	var spec: Dictionary = SPECS.get(kind, SPECS["blade"])
	return Vector2(spec["texture"].get_size()) == Vector2(spec["atlas_size"])


static func _source_cell(kind: String, action: String, frame: int) -> Rect2:
	var spec: Dictionary = SPECS.get(kind, SPECS["blade"])
	var columns: int = int(spec["columns"])
	var rows: int = int(spec["rows"])
	var row: int = int(spec["actions"].get(action, spec["actions"]["idle"]))
	var safe_frame := clampi(frame, 0, columns - 1)
	var atlas_size: Vector2 = spec["atlas_size"]
	var x0 := roundi(safe_frame * atlas_size.x / columns)
	var x1 := roundi((safe_frame + 1) * atlas_size.x / columns)
	var y0 := roundi(row * atlas_size.y / rows)
	var y1 := roundi((row + 1) * atlas_size.y / rows)
	return Rect2(x0, y0, x1 - x0, y1 - y0)
