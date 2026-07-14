extends RefCounted

const WEAPON: Texture2D = preload("res://assets/vfx/sequences/weapon_actions.png")
const IMPACT: Texture2D = preload("res://assets/vfx/sequences/impact_actions.png")
const ELEMENT: Texture2D = preload("res://assets/vfx/sequences/element_actions.png")
const DUANSHUI: Texture2D = preload("res://assets/vfx/sequences/duanshui_subskills.png")
const SHUANGREN: Texture2D = preload("res://assets/vfx/sequences/shuangren_subskills.png")
const MOHONG: Texture2D = preload("res://assets/vfx/sequences/mohong_subskills.png")
const LIESHAN: Texture2D = preload("res://assets/vfx/sequences/lieshan_subskills.png")
const YINXUE: Texture2D = preload("res://assets/vfx/sequences/yinxue_subskills.png")
const PROGRESSION: Texture2D = preload("res://assets/vfx/sequences/progression_actions.png")

const WEAPON_SIZE := Vector2(1774, 887)
const IMPACT_SIZE := Vector2(1774, 887)
const ELEMENT_SIZE := Vector2(1448, 1086)
const SUBSKILL_SIZE := Vector2(1774, 887)
const MOHONG_SIZE := Vector2(1691, 930)
const PROGRESSION_SIZE := Vector2(1536, 1024)
const FRAMES := 8

const VFX_DESCRIPTIONS := {
	"combo_1": {"name": "第一段普攻", "desc": "快速横斩，刀光较短呈弧线划过，起手攻击，水墨拖尾轻淡"},
	"combo_2": {"name": "第二段普攻", "desc": "斜向上挑斩，刀光中等长度，连接第一段，带轻微上扬轨迹"},
	"combo_3": {"name": "第三段普攻", "desc": "强力下劈，刀光最长，带有重量感和冲击波纹，终结技"},
	"dodge": {"name": "闪避残影", "desc": "角色闪避时留下的水墨残影轨迹，呈半透明拖尾，持续约0.3秒"},
	"hit": {"name": "普通命中", "desc": "击中敌人时的水墨飞溅效果，黑色墨点四散，伴随轻微震动"},
	"crit": {"name": "暴击", "desc": "暴击命中时的金色闪光与强烈水墨飞溅，金色光晕爆发，墨点更密集"},
	"shield_break": {"name": "破盾", "desc": "敌人护盾被打破时的碎裂特效，金色碎片四散，伴随护盾破裂声"},
	"death": {"name": "死亡", "desc": "敌人死亡时的消散特效，化为墨点向上飘散，Boss版本范围更大更华丽"},
	"metal": {"name": "金元素", "desc": "金属性攻击的金色刃光效果，尖锐锋利的金色刀光，带金属光泽"},
	"wood": {"name": "木元素", "desc": "木属性攻击的绿色藤蔓缠绕效果，藤蔓从攻击点向外蔓延缠绕敌人"},
	"water": {"name": "水元素", "desc": "水属性攻击的蓝色水流冲击效果，水流呈波浪状向前涌进"},
	"fire": {"name": "火元素", "desc": "火属性攻击的红色火焰爆发效果，火焰呈扇形喷发，带有余烬"},
	"earth": {"name": "土元素", "desc": "土属性攻击的棕色岩石碎裂效果，岩石碎片从地面隆起并四散"},
	"harmony": {"name": "五行圆满", "desc": "五行圆满格局激活时的彩色光环效果，五色光环从中心向外扩散，持续闪烁"},
	"sword_wave": {"name": "剑气波", "desc": "短剑副技能，发射一道远程剑气，呈直线飞行，带蓝色光晕"},
	"blink_slash": {"name": "瞬步斩", "desc": "短剑副技能，瞬间闪现到目标位置并斩击，闪现时带残影"},
	"combo_haste": {"name": "连击加速", "desc": "短剑副技能，进入连击加速状态，角色周围出现金色气流环绕"},
	"ice_scar": {"name": "冰痕", "desc": "双剑副技能，地面留下冰痕轨迹，蓝色冰裂纹路持续伤害敌人"},
	"cold_flash": {"name": "寒闪", "desc": "双剑副技能，向前冲刺并留下寒气轨迹，带蓝色冰晶粒子"},
	"frost_armor": {"name": "霜甲", "desc": "双剑副技能，给自己添加冰霜护甲，蓝色冰甲覆盖全身"},
	"rainbow_cut": {"name": "虹斩", "desc": "墨虹副技能，释放彩虹色刀光，七彩光芒呈弧形斩出"},
	"ink_shadow": {"name": "墨影", "desc": "墨虹副技能，召唤墨影分身攻击，黑色虚影从角色周围浮现"},
	"return_blade": {"name": "归刃", "desc": "墨虹副技能，刀飞出后飞回造成二次伤害，带回旋轨迹"},
	"mountain_cleave": {"name": "裂山", "desc": "裂山副技能，释放巨大的横向斩击，刀光呈山峦起伏状"},
	"earth_quake": {"name": "地震", "desc": "裂山副技能，引发地面震动，地面隆起并产生冲击波"},
	"iron_wall": {"name": "铁壁", "desc": "裂山副技能，生成岩石护盾，棕色岩石从地面升起形成防御墙"},
	"blood_rage": {"name": "血怒", "desc": "饮血副技能，进入狂暴状态提升攻击力，红色血雾环绕角色"},
	"soul_bite": {"name": "噬魂", "desc": "饮血副技能，吸取敌人生命，黑色能量线从敌人流向角色"},
	"blood_shield": {"name": "血盾", "desc": "饮血副技能，用鲜血形成护盾，红色血膜覆盖角色周围"},
	"relic_get": {"name": "遗物获得", "desc": "获得遗物时的拾取特效，物品从地面飘起，带金色光晕和粒子"},
	"weapon_get": {"name": "武器获得", "desc": "获得武器时的拾取特效，武器从地面升起旋转，带蓝色光芒"},
	"pattern_low": {"name": "低阶格局", "desc": "激活低阶五行格局时的特效，单色光环从中心扩散，持续约1秒"},
	"pattern_mid": {"name": "中阶格局", "desc": "激活中阶五行格局时的特效，双色光环交错旋转，更明亮持久"},
	"pattern_high": {"name": "高阶格局", "desc": "激活高阶五行格局时的特效，三色光环叠加爆发，光芒四射"},
}

const ROWS := {
	"combo_1": {"texture": WEAPON, "atlas_size": WEAPON_SIZE, "row": 0, "rows": 4, "active_frames": 7},
	"combo_2": {"texture": WEAPON, "atlas_size": WEAPON_SIZE, "row": 1, "rows": 4, "active_frames": 7},
	"combo_3": {"texture": WEAPON, "atlas_size": WEAPON_SIZE, "row": 2, "rows": 4, "active_frames": 7},
	"dodge": {"texture": WEAPON, "atlas_size": WEAPON_SIZE, "row": 3, "rows": 4},
	"hit": {"texture": IMPACT, "atlas_size": IMPACT_SIZE, "row": 0, "rows": 4, "active_frames": 7},
	"crit": {"texture": IMPACT, "atlas_size": IMPACT_SIZE, "row": 1, "rows": 4, "active_frames": 7},
	"shield_break": {"texture": IMPACT, "atlas_size": IMPACT_SIZE, "row": 2, "rows": 4},
	"death": {"texture": IMPACT, "atlas_size": IMPACT_SIZE, "row": 3, "rows": 4},
	"metal": {"texture": ELEMENT, "atlas_size": ELEMENT_SIZE, "row": 0, "rows": 6, "x_bounds": [0, 193, 393, 616, 834, 1031, 1225, 1349, 1448], "anchors": [Vector2(0.536, 0.564), Vector2(0.532, 0.580), Vector2(0.540, 0.569), Vector2(0.537, 0.561), Vector2(0.485, 0.544), Vector2(0.479, 0.544), Vector2(0.577, 0.588), Vector2(0.577, 0.588)]},
	"wood": {"texture": ELEMENT, "atlas_size": ELEMENT_SIZE, "row": 1, "rows": 6, "x_bounds": [0, 186, 353, 599, 846, 1036, 1241, 1391, 1448], "anchors": [Vector2(0.527, 0.539), Vector2(0.533, 0.594), Vector2(0.520, 0.558), Vector2(0.514, 0.558), Vector2(0.500, 0.564), Vector2(0.507, 0.588), Vector2(0.400, 0.555), Vector2(0.400, 0.555)]},
	"water": {"texture": ELEMENT, "atlas_size": ELEMENT_SIZE, "row": 2, "rows": 6, "x_bounds": [0, 159, 371, 601, 827, 1038, 1219, 1369, 1448], "anchors": [Vector2(0.585, 0.572), Vector2(0.509, 0.564), Vector2(0.524, 0.552), Vector2(0.493, 0.525), Vector2(0.500, 0.569), Vector2(0.511, 0.699), Vector2(0.357, 0.751), Vector2(0.357, 0.751)]},
	"fire": {"texture": ELEMENT, "atlas_size": ELEMENT_SIZE, "row": 3, "rows": 6, "x_bounds": [0, 157, 351, 565, 822, 1009, 1198, 1390, 1448], "anchors": [Vector2(0.532, 0.525), Vector2(0.552, 0.530), Vector2(0.521, 0.450), Vector2(0.537, 0.445), Vector2(0.476, 0.519), Vector2(0.444, 0.550), Vector2(0.474, 0.613), Vector2(0.474, 0.613)]},
	"earth": {"texture": ELEMENT, "atlas_size": ELEMENT_SIZE, "row": 4, "rows": 6, "x_bounds": [0, 151, 344, 558, 808, 1026, 1225, 1315, 1448], "anchors": [Vector2(0.563, 0.494), Vector2(0.557, 0.406), Vector2(0.509, 0.528), Vector2(0.506, 0.528), Vector2(0.502, 0.461), Vector2(0.495, 0.528), Vector2(0.572, 0.630), Vector2(0.572, 0.630)]},
	"harmony": {"texture": ELEMENT, "atlas_size": ELEMENT_SIZE, "row": 5, "rows": 6, "x_bounds": [0, 187, 366, 566, 776, 983, 1150, 1307, 1448], "anchors": [Vector2(0.543, 0.334), Vector2(0.520, 0.348), Vector2(0.488, 0.365), Vector2(0.507, 0.370), Vector2(0.495, 0.381), Vector2(0.506, 0.356), Vector2(0.500, 0.373), Vector2(0.500, 0.373)]},
	"sword_wave": {"texture": DUANSHUI, "atlas_size": SUBSKILL_SIZE, "row": 0, "rows": 3},
	"blink_slash": {"texture": DUANSHUI, "atlas_size": SUBSKILL_SIZE, "row": 1, "rows": 3},
	"combo_haste": {"texture": DUANSHUI, "atlas_size": SUBSKILL_SIZE, "row": 2, "rows": 3, "active_frames": 7, "anchors": [Vector2(0.491, 0.333), Vector2(0.401, 0.329), Vector2(0.502, 0.345), Vector2(0.644, 0.351), Vector2(0.498, 0.356), Vector2(0.430, 0.356), Vector2(0.412, 0.459)]},
	"ice_scar": {"texture": SHUANGREN, "atlas_size": SUBSKILL_SIZE, "row": 0, "rows": 3},
	"cold_flash": {"texture": SHUANGREN, "atlas_size": SUBSKILL_SIZE, "row": 1, "rows": 3},
	"frost_armor": {"texture": SHUANGREN, "atlas_size": SUBSKILL_SIZE, "row": 2, "rows": 3, "anchors": [Vector2(0.468, 0.355), Vector2(0.459, 0.346), Vector2(0.484, 0.351), Vector2(0.493, 0.351), Vector2(0.498, 0.350), Vector2(0.514, 0.341), Vector2(0.525, 0.331), Vector2(0.486, 0.329)]},
	"rainbow_cut": {"texture": MOHONG, "atlas_size": MOHONG_SIZE, "row": 0, "rows": 3},
	"ink_shadow": {"texture": MOHONG, "atlas_size": MOHONG_SIZE, "row": 1, "rows": 3},
	"return_blade": {"texture": MOHONG, "atlas_size": MOHONG_SIZE, "row": 2, "rows": 3},
	"mountain_cleave": {"texture": LIESHAN, "atlas_size": SUBSKILL_SIZE, "row": 0, "rows": 3},
	"earth_quake": {"texture": LIESHAN, "atlas_size": SUBSKILL_SIZE, "row": 1, "rows": 3, "anchors": [Vector2(0.543, 0.475), Vector2(0.525, 0.502), Vector2(0.600, 0.517), Vector2(0.498, 0.493), Vector2(0.498, 0.492), Vector2(0.498, 0.492), Vector2(0.471, 0.531), Vector2(0.439, 0.600)]},
	"iron_wall": {"texture": LIESHAN, "atlas_size": SUBSKILL_SIZE, "row": 2, "rows": 3, "anchors": [Vector2(0.493, 0.392), Vector2(0.455, 0.390), Vector2(0.543, 0.426), Vector2(0.498, 0.414), Vector2(0.498, 0.402), Vector2(0.498, 0.416), Vector2(0.498, 0.426), Vector2(0.419, 0.436)]},
	"blood_rage": {"texture": YINXUE, "atlas_size": SUBSKILL_SIZE, "row": 0, "rows": 3, "anchors": [Vector2(0.633, 0.508), Vector2(0.586, 0.532), Vector2(0.500, 0.547), Vector2(0.498, 0.508), Vector2(0.498, 0.527), Vector2(0.498, 0.529), Vector2(0.495, 0.557), Vector2(0.495, 0.557)]},
	"soul_bite": {"texture": YINXUE, "atlas_size": SUBSKILL_SIZE, "row": 1, "rows": 3},
	"blood_shield": {"texture": YINXUE, "atlas_size": SUBSKILL_SIZE, "row": 2, "rows": 3, "anchors": [Vector2(0.525, 0.368), Vector2(0.536, 0.361), Vector2(0.559, 0.373), Vector2(0.498, 0.387), Vector2(0.498, 0.385), Vector2(0.498, 0.383), Vector2(0.435, 0.385), Vector2(0.435, 0.385)]},
	"relic_get": {"texture": PROGRESSION, "atlas_size": PROGRESSION_SIZE, "row": 0, "rows": 5, "x_bounds": [0, 204, 430, 641, 857, 1057, 1286, 1441, 1536], "anchors": [Vector2(0.534, 0.632), Vector2(0.524, 0.590), Vector2(0.512, 0.615), Vector2(0.486, 0.559), Vector2(0.482, 0.605), Vector2(0.507, 0.549), Vector2(0.574, 0.580), Vector2(0.574, 0.580)]},
	"weapon_get": {"texture": PROGRESSION, "atlas_size": PROGRESSION_SIZE, "row": 1, "rows": 5, "x_bounds": [0, 208, 428, 648, 856, 1063, 1296, 1407, 1536], "anchors": [Vector2(0.531, 0.561), Vector2(0.516, 0.541), Vector2(0.505, 0.532), Vector2(0.495, 0.541), Vector2(0.490, 0.534), Vector2(0.464, 0.534), Vector2(0.667, 0.539), Vector2(0.667, 0.539)]},
	"pattern_low": {"texture": PROGRESSION, "atlas_size": PROGRESSION_SIZE, "row": 2, "rows": 5, "x_bounds": [0, 208, 416, 645, 864, 1066, 1284, 1400, 1536], "anchors": [Vector2(0.555, 0.468), Vector2(0.486, 0.473), Vector2(0.509, 0.458), Vector2(0.489, 0.569), Vector2(0.502, 0.456), Vector2(0.493, 0.453), Vector2(0.560, 0.561), Vector2(0.560, 0.561)]},
	"pattern_mid": {"texture": PROGRESSION, "atlas_size": PROGRESSION_SIZE, "row": 3, "rows": 5, "x_bounds": [0, 203, 413, 632, 863, 1069, 1290, 1429, 1536], "anchors": [Vector2(0.502, 0.354), Vector2(0.507, 0.366), Vector2(0.507, 0.500), Vector2(0.494, 0.498), Vector2(0.490, 0.368), Vector2(0.473, 0.378), Vector2(0.640, 0.422), Vector2(0.640, 0.422)]},
	"pattern_high": {"texture": PROGRESSION, "atlas_size": PROGRESSION_SIZE, "row": 4, "rows": 5, "x_bounds": [0, 204, 412, 636, 854, 1063, 1259, 1412, 1536], "anchors": [Vector2(0.488, 0.388), Vector2(0.526, 0.380), Vector2(0.518, 0.366), Vector2(0.484, 0.376), Vector2(0.502, 0.376), Vector2(0.482, 0.395), Vector2(0.526, 0.398), Vector2(0.526, 0.398)]},
}


static func texture(kind: String) -> Texture2D:
	return ROWS.get(kind, ROWS["hit"])["texture"]


static func region(kind: String, frame: int) -> Rect2:
	var spec: Dictionary = ROWS.get(kind, ROWS["hit"])
	var cell := _cell_region(spec, frame)
	var padding := 3
	return Rect2(cell.position + Vector2(padding, padding), cell.size - Vector2(padding * 2, padding * 2))


static func anchor(kind: String, frame: int) -> Vector2:
	var spec: Dictionary = ROWS.get(kind, ROWS["hit"])
	var cell := _cell_region(spec, frame)
	var track: Array = spec.get("anchors", [])
	var source_anchor := Vector2(0.5, 0.5)
	if not track.is_empty():
		source_anchor = track[clampi(frame, 0, track.size() - 1)]
	var cropped := region(kind, frame)
	var source_point := cell.position + source_anchor * cell.size
	return (source_point - cropped.position) / cropped.size


static func atlas_matches_texture(kind: String) -> bool:
	var spec: Dictionary = ROWS.get(kind, ROWS["hit"])
	return Vector2(spec["texture"].get_size()) == Vector2(spec["atlas_size"])


static func _cell_region(spec: Dictionary, frame: int) -> Rect2:
	var safe_frame := clampi(frame, 0, FRAMES - 1)
	var atlas_size: Vector2 = spec["atlas_size"]
	var row: int = int(spec["row"])
	var rows: int = int(spec["rows"])
	var x_bounds: Array = spec.get("x_bounds", [])
	var x0 := int(x_bounds[safe_frame]) if x_bounds.size() == FRAMES + 1 else roundi(safe_frame * atlas_size.x / FRAMES)
	var x1 := int(x_bounds[safe_frame + 1]) if x_bounds.size() == FRAMES + 1 else roundi((safe_frame + 1) * atlas_size.x / FRAMES)
	var y0 := roundi(row * atlas_size.y / rows)
	var y1 := roundi((row + 1) * atlas_size.y / rows)
	return Rect2(x0, y0, x1 - x0, y1 - y0)


static func has_sequence(kind: String) -> bool:
	return ROWS.has(kind)


static func frame_count(kind: String) -> int:
	return int(ROWS.get(kind, ROWS["hit"]).get("active_frames", FRAMES))
