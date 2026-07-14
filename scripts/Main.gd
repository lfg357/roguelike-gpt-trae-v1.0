extends Node2D

# --- 信号系统：模块间事件广播 ---
signal player_damaged(amount: float, current_hp: float)
signal enemy_killed(kind: String, pos: Vector2)
signal pattern_discovered(pattern_name: String)
signal combo_discovered(combo_name: String)
signal room_entered(room_index: int, room_type: String)
signal floor_changed(floor: int)
signal disk_changed(disk: Array)
signal process_frame()

const INK_THEME = preload("res://scripts/ui/InkTheme.gd")
const CHARACTER_SEQUENCES = preload("res://scripts/art/CharacterSequences.gd")
const VFX_SEQUENCES = preload("res://scripts/vfx/VFXSequences.gd")

const PLAYER_MODULE = preload("res://scripts/Player.gd")
const ENEMY_MODULE = preload("res://scripts/Enemy.gd")
const ROOM_MODULE = preload("res://scripts/Room.gd")
const RELIC_MODULE = preload("res://scripts/Relic.gd")
const DISK_MODULE = preload("res://scripts/FiveElementDisk.gd")
const COMBAT_FEEDBACK_MODULE = preload("res://scripts/CombatFeedback.gd")

var player_module = null
var enemy_module = null
var room_module = null
var relic_module = null
var disk_module = null
var combat_feedback_module = null

const VIEW_SIZE := Vector2(1280, 720)
const LEFT_RAIL := Rect2(0, 0, 142, 720)
const RIGHT_RAIL := Rect2(1014, 0, 266, 720)
const TOP_SAFE := Rect2(142, 0, 872, 78)
const BOTTOM_SAFE := Rect2(142, 650, 872, 70)
const ARENA := Rect2(154, 90, 848, 548)
const ATTACK_RATE_MULT := 1.22
const DOOR_REACH := 72.0
const MAP_COLS := 6
const MAP_ROWS := 5
const BOSS_PHASE_ONE_SEQUENCE := ["cleave", "cleave", "sweep", "cleave", "charge"]
const BOSS_PHASE_TWO_SEQUENCE := ["cleave", "sweep", "cleave", "charge"]
const BOSS_ACTION_NAMES := {
	"cleave": "举刀蓄力",
	"sweep": "横扫蓄力",
	"charge": "锁定冲刺",
}
const RELIC_BUY_PRICES := {"白": 30, "蓝": 60, "紫": 120, "金": 200}
const RELIC_SELL_PRICES := {"白": 12, "蓝": 24, "紫": 48, "金": 80}
const WEAPON_BUY_PRICE := 80
const SHOP_REFRESH_PRICE := 20
const RESETTABLE_VFX_SLOTS := {
	"relic_get": "progression",
	"weapon_get": "progression",
	"pattern_low": "progression",
	"pattern_mid": "progression",
	"pattern_high": "progression",
	"harmony": "progression",
}
const LORE_STELE_POS := Vector2(260, 220)
const LORE_TEXTS := [
	"残卷：墨渊一开，五行失衡。入局者若只逐强，终会被局吞没。",
	"残卷：金锋破甲，木息续命，水缓其势，火逼其形，土守其心。",
	"残卷：秘境之门随灵脉而开，归路与前路常在同一笔墨之间。",
]
const WEAPON_VARIANTS := {
	"duanshui": [
		{"id": "sword_wave", "name": "剑气斩", "desc": "右键释放直线剑气，穿透路径敌人。"},
		{"id": "blink_slash", "name": "瞬步斩", "desc": "右键向鼠标方向突进并斩击落点。"},
		{"id": "combo_haste", "name": "连环剑", "desc": "右键进入短暂连环状态，攻速提升。"},
	],
	"shuangren": [
		{"id": "ice_scar", "name": "冰痕斩", "desc": "右键在前方留下冰痕，伤害并减速敌人。"},
		{"id": "cold_flash", "name": "寒光闪", "desc": "右键闪身并造成冰寒范围伤害。"},
		{"id": "frost_armor", "name": "霜甲", "desc": "右键获得短暂霜甲减伤。"},
	],
	"mohong": [
		{"id": "rainbow_cut", "name": "虹斩", "desc": "右键释放长距离贯穿斩。"},
		{"id": "ink_shadow", "name": "墨影", "desc": "右键留下墨影，短暂后爆开。"},
		{"id": "return_blade", "name": "归刃", "desc": "右键掷出回旋剑影，两段伤害。"},
	],
	"lieshan": [
		{"id": "mountain_cleave", "name": "崩山斩", "desc": "右键重劈前方大范围敌人。"},
		{"id": "earth_quake", "name": "地裂震", "desc": "右键震裂周身地面并击退敌人。"},
		{"id": "iron_wall", "name": "铁壁斩", "desc": "右键进入铁壁姿态，减伤并震退近敌。"},
	],
	"yinxue": [
		{"id": "blood_rage", "name": "血怒", "desc": "右键以生命为代价短暂提升攻击。"},
		{"id": "soul_bite", "name": "噬魂斩", "desc": "右键释放吸血斩，命中时回复生命。"},
		{"id": "blood_shield", "name": "血盾", "desc": "右键消耗少量生命获得血盾减伤。"},
	],
}
const ELEMENT_NAMES := {
	"none": "无",
	"metal": "金",
	"wood": "木",
	"water": "水",
	"fire": "火",
	"earth": "土",
}
const ELEMENT_COLORS := {
	"none": Color(0.85, 0.81, 0.73),
	"metal": Color(0.86, 0.86, 0.84),
	"wood": Color(0.44, 0.75, 0.53),
	"water": Color(0.36, 0.61, 0.78),
	"fire": Color(0.85, 0.42, 0.33),
	"earth": Color(0.79, 0.66, 0.41),
}
const RARITY_COLORS := {
	"白": Color(0.82, 0.82, 0.78),
	"蓝": Color(0.35, 0.62, 0.95),
	"紫": Color(0.68, 0.43, 0.96),
	"金": Color(0.95, 0.72, 0.28),
}
const TAG_COLORS := {
	"锐": Color(0.86, 0.86, 0.84),
	"迅": Color(0.45, 0.74, 0.95),
	"厚": Color(0.79, 0.66, 0.41),
	"吸": Color(0.44, 0.75, 0.53),
	"冻": Color(0.36, 0.61, 0.78),
	"焚": Color(0.85, 0.42, 0.33),
	"裂": Color(0.90, 0.56, 0.30),
	"魂": Color(0.66, 0.55, 0.88),
	"蚀": Color(0.40, 0.70, 0.66),
	"障": Color(0.72, 0.68, 0.54),
}
const PATTERN_DESCS := {
	"锐金之极": "5金：暴击率+10%，命中时触发金刃切割造成额外真实伤害。",
	"生生不息": "5木：最大HP+15，击杀回复15%最大HP，每秒回复0.2HP。",
	"渊流无尽": "5水：技能冷却-15%，攻击20%概率减速敌人。",
	"焚天烈焰": "5火：攻击力+10%，攻击附带灼烧效果。",
	"万钧之重": "5土：减伤+15%，致死时免疫一次并回复30%HP。",
	"金水相生": "金+水：暴击率+8%，暴击后下次攻击附带水溅射。",
	"水木相生": "水+木：每秒回复1HP，每5次攻击额外回复5%最大HP。",
	"木火相生": "木+火：攻击力+5%，灼烧伤害+40%，灼烧会传染附近敌人。",
	"火土相生": "火+土：减伤+8%，受击后3秒内减伤额外+10%。",
	"土金相生": "土+金：攻击力+5%，累计造成100伤害后下次攻击x1.5。",
	"金木交锋": "金克木：破甲+30%，暴击+4%，自身减伤-4%。",
	"木土相争": "木克土：击杀回复8%最大HP，攻击速度+5%。",
	"土水交冲": "土克水：攻击18%概率生成泥沼减速敌人，自身移速-12%，闪避CD+0.25秒。",
	"水火不容": "水克火：攻击20%概率触发蒸汽爆发，攻击力+8%，自身减伤-5%。",
	"火金相克": "火克金：暴击率+10%，攻击附带灼烧，非暴击伤害-12%。",
	"金水木·涌泉": "金+水+木：暴击率+5%，每秒回复0.8HP，攻击力+4%，形成暴击→回复→伤害循环。",
	"水木火·燎原": "水+木+火：每秒回复0.8HP，灼烧伤害+35%，回复效果触发火焰脉冲。",
	"木火土·熔铸": "木+火+土：攻击力+6%，减伤+6%，灼烧伤害+25%，灼烧击杀掉落熔渣。",
	"火土金·锻锋": "火+土+金：攻击力+8%，暴击率+4%，受击累积锻力，满5层下次攻击x2.5。",
	"土金水·沉渊": "土+金+水：减伤+8%，减速概率+12%，减伤累积渊力，满100释放全屏水脉冲。",
	"火水木·蒸腾": "火+水+木：攻击18%概率触发毒雾，灼烧伤害-20%，减速概率+6%。",
	"土水火·泥焰": "土+水+火：攻击20%概率喷发泥焰，攻击速度-4%。",
	"金木火·淬刃": "金+木+火：无视20%护甲，暴击率+5%，灼烧伤害+18%。",
	"水土金·沉锻": "水+土+金：减伤+10%，HP回复效果-25%。",
	"木火土·灰烬": "木+火+土：击杀回复4%最大HP，攻击力+6%，自然回血-30%。",
	"四象轮转": "4种各1：全属性+6%，每5秒切换活跃元素，活跃元素效果+50%。",
	"金水火土·破界": "缺木：攻击力+10%，暴击率+6%，无自然回复，攻击10%概率元素崩裂。",
	"木火土水·四象归元": "缺金：每秒回复1HP，减伤+8%，灼烧伤害+20%，暴击效果失效。",
	"五行圆满": "五行各1：暴击率+4%，每秒回复0.4HP，技能冷却-4%，攻击力+4%，减伤+4%，减速概率+5%，灼烧伤害+10%，每10秒触发五行归元脉冲。",
}
const TAG_COMBO_DESCS := {
	"破甲墨锋": "锐+裂：暴击率+8%，锋利的墨刃擅长击碎敌人护甲。",
	"爆燃裂帛": "焚+裂：灼烧伤害+60%，火焰撕裂敌人防御造成持续燃烧。",
	"摄魂回元": "吸+魂：击杀回复6%最大生命值，吸取魂魄转化为自身气血。",
	"寒蚀入骨": "冻+蚀：攻击12%概率减速敌人，寒气侵蚀骨骼持续削弱。",
	"山门不动": "厚+障：减伤+8%，如同山门般稳固不可动摇。",
	"聚力穿心": "锐+蓄：攻击力+8%，暴击率+5%，蓄力一击穿透敌人心脏。",
	"雷霆一击": "锐+震：暴击率+6%，攻击力+5%，攻击附带雷霆震动效果。",
	"疾风剑": "锐+迅：攻击速度+8%，暴击率+5%，快如疾风的剑法。",
	"背刺之影": "锐+影：暴击率+10%，攻击力+4%，擅长从阴影中发动致命一击。",
	"穿透弹射": "锐+弹：攻击范围+20%，暴击率+5%，攻击可穿透敌人并弹射。",
	"焰刃": "焚+锐：灼烧伤害+30%，暴击率+5%，刀刃缠绕火焰。",
	"炽焰重击": "焚+蓄：攻击必附带灼烧(+1层)，攻击力+5%，蓄力重击引燃敌人。",
	"腐蚀烈焰": "焚+蚀：灼烧伤害+35%，攻击力+4%，火焰中混合腐蚀性物质。",
	"烈焰爆破": "焚+震：灼烧伤害+25%，攻击范围+15%，火焰引发范围爆破。",
	"疾风烈焰": "焚+迅：攻击速度+8%，灼烧伤害+20%，快速攻击带起火焰旋风。",
	"碎地冲击": "裂+震：攻击力+6%，攻击范围+15%，攻击引发地面碎裂冲击。",
	"玄甲反震": "厚+镜：减伤+6%，受到攻击时反弹4%伤害给攻击者。",
	"反射结界": "障+镜：减伤+5%，攻击范围+10%，护盾可反射部分伤害。",
	"铁壁疾行": "厚+迅：减伤+5%，攻击速度+6%，坚固护甲不减机动性。",
	"血甲": "吸+厚：击杀回复4%HP，减伤+5%，用鲜血强化护甲。",
	"亡魂护甲": "魂+厚：击杀回复5%HP，减伤+6%，亡魂环绕形成护甲。",
	"冰封屏障": "障+冻：减伤+6%，攻击8%概率减速敌人，冰霜形成屏障。",
	"冰封锁链": "冻+缚：减速概率+15%，减伤+4%，冰霜锁链困住敌人。",
	"腐蚀锁链": "蚀+缚：减速概率+12%，攻击力+4%，腐蚀之力束缚敌人。",
	"潮汐引力": "聚+散：减速概率+10%，攻击速度+5%，引力与斥力交替作用。",
	"排斥护盾": "障+散：减伤+5%，攻击速度+5%，护盾将敌人推开。",
	"铁锁横江": "厚+缚：减伤+8%，攻击力+3%，如同铁锁般坚固的防御。",
	"鬼步": "迅+影：攻击速度+10%，闪避CD-0.2秒，如同鬼魅般移动。",
	"疾速弹射": "弹+迅：攻击速度+6%，攻击范围+15%，快速攻击附带弹射效果。",
	"疾风吸血": "吸+迅：攻击速度+8%，击杀回复3%HP，快速攻击中吸取生命。",
	"亡魂疾行": "魂+迅：攻击速度+10%，击杀回复4%HP，亡魂加持提升速度。",
	"灵甲护体": "召+厚：减伤+4%，最大HP+10，召唤灵体形成护甲。",
	"灵盾": "召+障：减伤+5%，每秒回复0.3HP，召唤灵体护盾。",
	"冰冻烙印": "印+冻：减速概率+14%，攻击力+5%，印记标记敌人后释放冰霜。",
	"弱点洞悉": "印+锐：暴击率+8%，攻击力+6%，标记敌人弱点后精准打击。",
}
const TAG_DESCS := {
	"锐": "锋锐、切割、暴击相关。",
	"迅": "身法、移速、闪避节奏相关。",
	"厚": "减伤、护甲、承伤相关。",
	"吸": "回复、吸取、续航相关。",
	"冻": "减速、冻结、控制相关。",
	"焚": "灼烧、火焰、持续伤害相关。",
	"裂": "破甲、爆裂、范围冲击相关。",
	"魂": "击杀、灵魂、亡语相关。",
	"蚀": "侵蚀、持续削弱相关。",
	"障": "护盾、屏障、防御相关。",
}
const RUN_TELEMETRY := preload("res://scripts/RunTelemetry.gd")
const FIVE_ELEMENT_RULES := preload("res://scripts/FiveElementRules.gd")

var relics: Array[Dictionary] = [
	# ── P0 通用遗物（白，1标签） ──
	{"id": "ink_blade", "name": "墨锋", "rarity": "白", "element": "none", "tags": ["锐"], "stats": {"damage": 0.15}, "desc": "攻击伤害+15%"},
	{"id": "swift_step", "name": "疾风步", "rarity": "白", "element": "none", "tags": ["迅"], "stats": {"speed": 0.10}, "desc": "移速+10%"},
	{"id": "iron_body", "name": "铁骨", "rarity": "白", "element": "metal", "tags": ["厚"], "stats": {"reduction": 0.10}, "desc": "减伤+10%"},
	{"id": "wood_heart", "name": "木灵心", "rarity": "白", "element": "wood", "tags": ["吸"], "stats": {"max_hp": 20}, "desc": "最大HP+20"},
	{"id": "water_talisman", "name": "水符", "rarity": "白", "element": "water", "tags": ["冻"], "stats": {"slow_chance": 0.10}, "desc": "攻击10%概率减速"},
	{"id": "fire_pearl", "name": "火珠", "rarity": "白", "element": "fire", "tags": ["焚"], "stats": {"burn": 1.0}, "desc": "攻击附带灼烧"},
	{"id": "earth_stone", "name": "土魄石", "rarity": "白", "element": "earth", "tags": ["厚"], "stats": {"reduction": 0.08}, "desc": "减伤+8%"},
	# ── P0 通用遗物（蓝，1-2标签） ──
	{"id": "gold_ring", "name": "金芒戒", "rarity": "蓝", "element": "metal", "tags": ["锐", "裂"], "stats": {"crit": 0.08}, "desc": "暴击率+8%"},
	{"id": "spirit_sword", "name": "灵剑", "rarity": "蓝", "element": "metal", "tags": ["锐", "焚"], "stats": {"damage": 0.25}, "desc": "攻击伤害+25%"},
	{"id": "jade_pendant", "name": "玉珮", "rarity": "蓝", "element": "wood", "tags": ["吸", "魂"], "stats": {"regen": 1.0}, "desc": "每秒回复1HP"},
	{"id": "black_ink", "name": "玄墨", "rarity": "蓝", "element": "water", "tags": ["冻", "蚀"], "stats": {"range": 0.20}, "desc": "攻击范围+20%"},
	{"id": "flame_talisman", "name": "烈焰符", "rarity": "蓝", "element": "fire", "tags": ["焚", "裂"], "stats": {"burn_power": 0.50}, "desc": "燃烧伤害+50%"},
	# ── P0 通用遗物（紫，2-3标签） ──
	{"id": "mountain_stele", "name": "山岳碑", "rarity": "紫", "element": "earth", "tags": ["厚", "障"], "stats": {"reduction": 0.25, "max_hp": 30}, "desc": "减伤+25%，最大HP+30"},
	# ── P0 通用遗物（金，3-4标签） ──
	{"id": "five_elements", "name": "五行令", "rarity": "金", "element": "none", "tags": ["锐", "吸", "焚", "冻", "厚"], "stats": {"all": 0.10, "resist": 0.20}, "desc": "全元素抗性+20%，全属性+10%"},
	# ── P1 通用遗物补充（白，1标签） ──
	{"id": "blood_drop", "name": "血露", "rarity": "白", "element": "fire", "tags": ["吸"], "stats": {"kill_heal": 0.03}, "desc": "击杀回复3%最大HP"},
	{"id": "ice_shard", "name": "冰棱", "rarity": "白", "element": "water", "tags": ["冻"], "stats": {"slow_chance": 0.08, "slow_power": 0.30}, "desc": "攻击8%概率减速30%"},
	{"id": "wind_chime", "name": "风铃", "rarity": "白", "element": "none", "tags": ["迅"], "stats": {"dodge_cd": -0.5}, "desc": "闪避冷却-0.5秒"},
	{"id": "stone_skin", "name": "石肤符", "rarity": "白", "element": "earth", "tags": ["障"], "stats": {"reduction": 0.06}, "desc": "减伤+6%"},
	{"id": "thorn_vine", "name": "荆藤", "rarity": "白", "element": "wood", "tags": ["反"], "stats": {"thorns": 3.0}, "desc": "受击反弹3点伤害"},
	{"id": "sharp_edge", "name": "锐锋", "rarity": "白", "element": "metal", "tags": ["锐"], "stats": {"damage": 0.10}, "desc": "攻击伤害+10%"},
	# ── P1 通用遗物补充（蓝，1-2标签） ──
	{"id": "crimson_mirror", "name": "赤镜", "rarity": "蓝", "element": "fire", "tags": ["焚", "反"], "stats": {"burn": 0.8, "thorns": 5.0}, "desc": "灼烧+反弹5伤害"},
	{"id": "frost_armor", "name": "霜甲", "rarity": "蓝", "element": "water", "tags": ["冻", "障"], "stats": {"reduction": 0.12, "slow_chance": 0.15}, "desc": "减伤+12%，受击15%减速敌人"},
	{"id": "root_network", "name": "根脉", "rarity": "蓝", "element": "wood", "tags": ["吸", "迅"], "stats": {"regen": 0.8, "speed": 0.06}, "desc": "每秒回复0.8HP，移速+6%"},
	{"id": "iron_will", "name": "铁意", "rarity": "蓝", "element": "metal", "tags": ["厚", "魂"], "stats": {"reduction": 0.10, "max_hp": 15}, "desc": "减伤+10%，最大HP+15"},
	{"id": "ink_shadow", "name": "墨影", "rarity": "蓝", "element": "none", "tags": ["迅", "裂"], "stats": {"speed": 0.12, "crit": 0.05}, "desc": "移速+12%，暴击+5%"},
	{"id": "lava_core", "name": "熔核", "rarity": "蓝", "element": "fire", "tags": ["焚", "锐"], "stats": {"burn": 1.2, "damage": 0.10}, "desc": "灼烧1.2，伤害+10%"},
	{"id": "spring_water", "name": "涌泉珠", "rarity": "蓝", "element": "water", "tags": ["吸", "冻"], "stats": {"regen": 1.2, "slow_chance": 0.08}, "desc": "回复1.2HP/s，8%减速"},
	{"id": "petrified_wood", "name": "化石木", "rarity": "蓝", "element": "earth", "tags": ["厚", "吸"], "stats": {"reduction": 0.08, "max_hp": 15}, "desc": "减伤+8%，HP+15"},
	# ── P1 通用遗物补充（紫，2-3标签） ──
	{"id": "volcano_heart", "name": "火山心", "rarity": "紫", "element": "fire", "tags": ["焚", "锐", "裂"], "stats": {"burn": 2.0, "burn_power": 0.40, "damage": 0.15}, "desc": "灼烧2+40%燃伤+伤害15%"},
	{"id": "glacier_soul", "name": "冰河魂", "rarity": "紫", "element": "water", "tags": ["冻", "障", "蚀"], "stats": {"slow_chance": 0.20, "slow_power": 0.40, "reduction": 0.10}, "desc": "20%减速40%+减伤10%"},
	{"id": "ancient_forest", "name": "古林印", "rarity": "紫", "element": "wood", "tags": ["吸", "魂", "迅"], "stats": {"regen": 2.0, "max_hp": 25, "speed": 0.08}, "desc": "回复2HP/s+HP+25+速8%"},
	{"id": "thunder_metal", "name": "雷金甲", "rarity": "紫", "element": "metal", "tags": ["锐", "厚", "裂"], "stats": {"damage": 0.20, "reduction": 0.12, "crit": 0.10}, "desc": "伤害20%+减伤12%+暴击10%"},
	{"id": "abyss_wall", "name": "深渊壁", "rarity": "紫", "element": "earth", "tags": ["厚", "障", "吸"], "stats": {"reduction": 0.18, "max_hp": 40, "regen": 0.5}, "desc": "减伤18%+HP+40+回复0.5"},
	# ── P1 燕无归角色专属（紫/金） ──
	{"id": "yan_ink_soul", "name": "墨魂", "rarity": "紫", "element": "water", "tags": ["迅", "锐", "蚀"], "stats": {"speed": 0.15, "damage": 0.12, "range": 0.15}, "desc": "燕无归专属：速15%+伤害12%+范围15%"},
	{"id": "yan_blade_dance", "name": "刀意", "rarity": "紫", "element": "metal", "tags": ["锐", "裂", "魂"], "stats": {"damage": 0.22, "crit": 0.12}, "desc": "燕无归专属：伤害22%+暴击12%"},
	{"id": "yan_void_step", "name": "虚空步", "rarity": "紫", "element": "none", "tags": ["迅", "障", "吸"], "stats": {"dodge_cd": -1.0, "reduction": 0.08, "regen": 1.0}, "desc": "燕无归专属：闪避-1s+减伤8%+回复1"},
	{"id": "yan_ultimate_ink", "name": "墨极", "rarity": "金", "element": "none", "tags": ["锐", "迅", "裂", "魂"], "stats": {"damage": 0.18, "speed": 0.12, "crit": 0.15, "range": 0.20}, "desc": "燕无归终极：伤害+速+暴击+范围全面提升"},
	# ── P1 配方遗物（触发特定组合的遗物，紫/金） ──
	{"id": "recipe_ink_break", "name": "破墨印", "rarity": "紫", "element": "metal", "tags": ["锐", "裂"], "stats": {"damage": 0.15, "armor_damage": 0.20}, "desc": "配方遗物：伤害15%+护甲穿透20%"},
	{"id": "recipe_flame_chain", "name": "焰链", "rarity": "紫", "element": "fire", "tags": ["焚", "蚀"], "stats": {"burn": 1.5, "burn_power": 0.60}, "desc": "配方遗物：灼烧1.5+燃伤60%"},
	{"id": "recipe_frost_seal", "name": "霜封", "rarity": "紫", "element": "water", "tags": ["冻", "障"], "stats": {"slow_chance": 0.25, "slow_power": 0.50, "reduction": 0.08}, "desc": "配方遗物：25%减速50%+减伤8%"},
	{"id": "recipe_root_blood", "name": "木血", "rarity": "紫", "element": "wood", "tags": ["吸", "魂"], "stats": {"regen": 2.5, "max_hp": 30}, "desc": "配方遗物：回复2.5HP/s+HP+30"},
	{"id": "recipe_earth_forge", "name": "地铸", "rarity": "紫", "element": "earth", "tags": ["厚", "障"], "stats": {"reduction": 0.20, "max_hp": 50}, "desc": "配方遗物：减伤20%+HP+50"},
	{"id": "recipe_duality", "name": "阴阳珮", "rarity": "金", "element": "none", "tags": ["锐", "吸"], "stats": {"damage": 0.10, "regen": 1.5, "all": 0.05}, "desc": "配方遗物：攻守兼备，全属性+5%"},
	{"id": "recipe_chaos_ink", "name": "混沌墨", "rarity": "金", "element": "none", "tags": ["锐", "焚", "冻", "裂"], "stats": {"damage": 0.12, "burn": 0.8, "slow_chance": 0.10, "crit": 0.10}, "desc": "配方遗物：四属性混沌之力"},
	{"id": "recipe_void_eye", "name": "虚瞳", "rarity": "金", "element": "water", "tags": ["冻", "蚀", "魂"], "stats": {"slow_chance": 0.20, "range": 0.30, "regen": 1.0}, "desc": "配方遗物：范围+30%+减速20%+回复1"},
	{"id": "recipe_phantom_blade", "name": "幻刃", "rarity": "金", "element": "metal", "tags": ["锐", "迅", "裂"], "stats": {"damage": 0.20, "speed": 0.10, "crit": 0.12, "armor_damage": 0.15}, "desc": "配方遗物：极致锋芒+护甲穿透"},
	{"id": "recipe_eternal_spring", "name": "不竭泉", "rarity": "金", "element": "wood", "tags": ["吸", "魂", "障"], "stats": {"regen": 3.0, "max_hp": 40, "reduction": 0.10}, "desc": "配方遗物：不竭回复+坚实壁垒"},
]

var weapons: Array[Dictionary] = [
	{"id": "blank", "name": "白板铁剑", "type": "剑", "rate": 1.5, "mult": 1.0, "range": 82.0, "desc": "开局武器"},
	{"id": "duanshui", "name": "断水", "type": "剑", "rate": 2.0, "mult": 0.7, "range": 86.0, "desc": "攻速最快，轻盈连贯"},
	{"id": "shuangren", "name": "霜刃", "type": "剑", "rate": 1.5, "mult": 1.0, "range": 90.0, "desc": "命中减速，手感偏控制"},
	{"id": "mohong", "name": "墨虹", "type": "剑", "rate": 1.5, "mult": 1.0, "range": 100.0, "desc": "第三段突刺更远"},
	{"id": "lieshan", "name": "裂山", "type": "刀", "rate": 1.0, "mult": 1.8, "range": 108.0, "desc": "慢速重击，第三段有冲击感"},
	{"id": "yinxue", "name": "饮血", "type": "刀", "rate": 1.2, "mult": 1.3, "range": 98.0, "desc": "攻击回血，低血量更稳"},
]

var enemy_specs := {
	"blade": {"name": "刀灵", "hp": 25.0, "damage": 10.0, "speed": 180.0, "ai": "chase", "element": "metal", "stone": 4, "radius": 13.0},
	"guard": {"name": "铜甲", "hp": 40.0, "damage": 8.0, "speed": 145.0, "ai": "shielder", "element": "metal", "stone": 5, "radius": 16.0},
	"dart": {"name": "镖手", "hp": 20.0, "damage": 12.0, "speed": 150.0, "ai": "ranged", "element": "metal", "stone": 4, "radius": 12.0},
	"elite": {"name": "金甲将", "hp": 105.0, "damage": 16.0, "speed": 178.0, "ai": "charger", "element": "metal", "stone": 25, "radius": 18.0},
	"boss": {"name": "金甲将军", "hp": 420.0, "damage": 18.0, "speed": 150.0, "ai": "boss", "element": "metal", "stone": 80, "radius": 30.0},
}

var state := "menu"
var current_floor := 1
var current_room := 0
var run_seed := 0
var telemetry: RefCounted = RUN_TELEMETRY.new()
var rooms: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var death_actors: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var impact_effects: Array[Dictionary] = []
var float_texts: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var boss_pillars: Array[Dictionary] = []
var boss_hazards: Array[Dictionary] = []
var discovered := {}
var slash := {}
var shake_amount := 0.0
var shake_time := 0.0
var shake_duration := 0.0
var shake_elapsed := 0.0
var hit_stop_time := 0.0
var hit_flash_time := 0.0
var hit_flash_duration := 0.0
var animation_clock := 0.0
var message_time := 0.0
var draw_camera_offset := Vector2.ZERO
var debug_anchor_targets: Array[Vector2] = []
var boss_started_at := 0
var screen_shake: Vector2 = Vector2.ZERO
var boss_portal := {}

var player := {
	"pos": Vector2(640, 360),
	"radius": 16.0,
	"hp": 100.0,
	"max_hp": 100.0,
	"base_speed": 230.0,
	"speed": 230.0,
	"damage": 10.0,
	"facing": 0.0,
	"combo": 0,
	"combo_expire": 0.0,
	"attack_cd": 0.0,
	"subskill_cd": 0.0,
	"dodge_cd": 0.0,
	"invuln": 0.0,
	"hurt": 0.0,
	"anim_action": "idle",
	"anim_time": 0.0,
	"anim_duration": 0.0,
	"loop_action": "idle",
	"loop_clock": 0.0,
	"haste": 0.0,
	"guard": 0.0,
	"rage": 0.0,
	"yuan_pulse_cd": 10.0,
	"stones": 0,
	"karma": 0,
	"weapon": {},
	"inventory": [],
	"disk": [null, null, null, null, null],
	"stats": {},
	"patterns": [],
	"combos": [],
	"element_counts": {},
	"lore_seen": {},
}

var font: Font
var ui_theme: Theme
var ui_layer: CanvasLayer
var menu_control: Control
var message_label: Label
var disk_panel: Panel
var disk_box: HBoxContainer
var inventory_grid: GridContainer
var build_label: Label
var relic_detail_label: RichTextLabel
var effect_grid: GridContainer
var weapon_choice_panel: Panel
var weapon_choice_label: RichTextLabel
var shop_panel: Panel
var shop_goods_box: VBoxContainer
var shop_sell_grid: GridContainer
var shop_detail_label: RichTextLabel
var settlement_panel: Panel
var settlement_label: RichTextLabel
var run_result_panel: Panel
var run_result_title: Label
var run_result_label: RichTextLabel
var hovered_relic = null
var selected_inventory_index := -1
var pending_weapon_drop := -1
var shop_stock: Array[Dictionary] = []

var drag_relic = null
var drag_source: String = ""
var drag_source_index: int = -1
var drag_target_index: int = -1
var drag_sprite: Label = null


func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	ui_theme = INK_THEME.make_theme(font)
	player_module = PLAYER_MODULE.new(self)
	enemy_module = ENEMY_MODULE.new(self)
	room_module = ROOM_MODULE.new(self)
	relic_module = RELIC_MODULE.new(self)
	disk_module = DISK_MODULE.new(self)
	combat_feedback_module = COMBAT_FEEDBACK_MODULE.new(self)
	# 连接信号 → 模块回调
	player_damaged.connect(combat_feedback_module._on_player_damaged)
	enemy_killed.connect(combat_feedback_module._on_enemy_killed)
	disk_changed.connect(disk_module._on_disk_changed)
	_bind_inputs()
	_build_ui()
	set_process(true)
	queue_redraw()


func _exit_tree() -> void:
	# RefCounted 模块会自动释放，这里只清理 Node 资源
	player_module = null
	enemy_module = null
	room_module = null
	relic_module = null
	disk_module = null
	combat_feedback_module = null


## 数据校验：检查 player 字典完整性，防止模块写入遗漏字段
func _validate_player() -> bool:
	if player == null:
		push_error("player is null")
		return false
	var required_keys := [
		"pos", "hp", "max_hp", "speed", "base_speed", "damage",
		"attack_cd", "subskill_cd", "dodge_cd",
		"anim_action", "anim_time", "loop_action", "loop_clock",
		"state", "stats", "patterns", "combos",
		"disk", "inventory", "weapon",
		"invuln", "hurt", "haste", "guard", "rage",
		"radius", "facing", "stones", "karma",
		"yuan_pulse_cd",
	]
	for key in required_keys:
		if not player.has(key):
			push_error("player missing key: %s" % key)
			return false
	# 确保数值字段不是 NaN
	for key in ["hp", "max_hp", "speed", "damage", "attack_cd", "dodge_cd"]:
		if is_nan(player[key]):
			push_error("player[%s] is NaN" % key)
			return false
	# 确保 hp 不超过 max_hp
	if player["hp"] > player["max_hp"]:
		player["hp"] = player["max_hp"]
	# 确保 disk 长度为 5
	if player["disk"].size() != 5:
		push_error("player disk size != 5, got %d" % player["disk"].size())
		return false
	return true


func _bind_inputs() -> void:
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_up", KEY_UP)
	_add_key_action("move_down", KEY_S)
	_add_key_action("move_down", KEY_DOWN)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_left", KEY_LEFT)
	_add_key_action("move_right", KEY_D)
	_add_key_action("move_right", KEY_RIGHT)
	_add_key_action("attack", KEY_J)
	_add_key_action("dodge", KEY_SPACE)
	_add_key_action("dodge", KEY_K)
	_add_key_action("interact", KEY_E)
	_add_key_action("disk", KEY_TAB)
	_add_key_action("inventory", KEY_I)
	_add_key_action("map", KEY_M)
	_add_key_action("restart", KEY_R)


func _add_key_action(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.keycode = keycode
	InputMap.action_add_event(action, event)


func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	menu_control = Control.new()
	menu_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_control.theme = ui_theme
	ui_layer.add_child(menu_control)

	var menu_bg := ColorRect.new()
	menu_bg.color = Color(0.025, 0.026, 0.027, 0.94)
	menu_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_control.add_child(menu_bg)

	var menu_box := VBoxContainer.new()
	menu_box.custom_minimum_size = Vector2(720, 260)
	menu_box.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_box.position = Vector2(280, 210)
	menu_control.add_child(menu_box)

	var kicker := Label.new()
	kicker.text = "墨渊初启 · 金域"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_font_size_override("font_size", 18)
	kicker.add_theme_color_override("font_color", Color(0.85, 0.70, 0.36))
	menu_box.add_child(kicker)

	var title := Label.new()
	title.text = "仙途·墨渊"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.91, 0.87, 0.79))
	menu_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "五行入局，落墨即杀"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.76, 0.73, 0.66))
	menu_box.add_child(subtitle)

	var start_button := Button.new()
	start_button.text = "入  境"
	start_button.custom_minimum_size = Vector2(240, 48)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(_start_game)
	menu_box.add_child(start_button)

	message_label = Label.new()
	message_label.visible = false
	message_label.position = Vector2(174, 616)
	message_label.custom_minimum_size = Vector2(728, 50)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Color(0.91, 0.87, 0.79))
	message_label.add_theme_stylebox_override("normal", INK_THEME.inset_style())
	message_label.theme = ui_theme
	ui_layer.add_child(message_label)

	disk_panel = Panel.new()
	disk_panel.visible = false
	disk_panel.position = Vector2(920, 82)
	disk_panel.custom_minimum_size = Vector2(348, 548)
	disk_panel.theme = ui_theme
	ui_layer.add_child(disk_panel)

	var panel_box := VBoxContainer.new()
	panel_box.position = Vector2(12, 12)
	panel_box.custom_minimum_size = Vector2(324, 524)
	disk_panel.add_child(panel_box)

	var top_row := HBoxContainer.new()
	panel_box.add_child(top_row)
	var disk_title := Label.new()
	disk_title.text = "五行盘"
	disk_title.add_theme_font_size_override("font_size", 20)
	disk_title.add_theme_color_override("font_color", INK_THEME.GOLD)
	top_row.add_child(disk_title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(42, 38)
	close_button.pressed.connect(func() -> void: _toggle_disk(false))
	top_row.add_child(close_button)

	disk_box = HBoxContainer.new()
	disk_box.custom_minimum_size = Vector2(324, 62)
	panel_box.add_child(disk_box)

	var inv_title := Label.new()
	inv_title.text = "背包"
	inv_title.add_theme_font_size_override("font_size", 17)
	panel_box.add_child(inv_title)

	inventory_grid = GridContainer.new()
	inventory_grid.columns = 4
	inventory_grid.custom_minimum_size = Vector2(324, 106)
	panel_box.add_child(inventory_grid)

	var effect_title := Label.new()
	effect_title.text = "已激活"
	effect_title.add_theme_font_size_override("font_size", 14)
	panel_box.add_child(effect_title)

	effect_grid = GridContainer.new()
	effect_grid.columns = 3
	effect_grid.custom_minimum_size = Vector2(324, 66)
	panel_box.add_child(effect_grid)

	var detail_title := Label.new()
	detail_title.text = "遗物 / 效果详情"
	detail_title.add_theme_font_size_override("font_size", 14)
	detail_title.add_theme_color_override("font_color", Color(0.76, 0.73, 0.66))
	panel_box.add_child(detail_title)

	relic_detail_label = RichTextLabel.new()
	relic_detail_label.bbcode_enabled = true
	relic_detail_label.fit_content = false
	relic_detail_label.scroll_active = false
	relic_detail_label.custom_minimum_size = Vector2(324, 112)
	relic_detail_label.add_theme_font_size_override("normal_font_size", 13)
	panel_box.add_child(relic_detail_label)

	build_label = Label.new()
	build_label.visible = false
	build_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_label.add_theme_font_size_override("font_size", 13)
	build_label.add_theme_color_override("font_color", Color(0.76, 0.73, 0.66))
	panel_box.add_child(build_label)

	_build_weapon_choice_ui()
	_build_shop_ui()
	_build_settlement_ui()
	_build_run_result_ui()


func _build_weapon_choice_ui() -> void:
	weapon_choice_panel = Panel.new()
	weapon_choice_panel.visible = false
	weapon_choice_panel.position = Vector2(280, 126)
	weapon_choice_panel.size = Vector2(720, 444)
	weapon_choice_panel.custom_minimum_size = Vector2(720, 444)
	weapon_choice_panel.theme = ui_theme
	ui_layer.add_child(weapon_choice_panel)

	var box := VBoxContainer.new()
	box.position = Vector2(20, 18)
	box.size = Vector2(680, 408)
	box.custom_minimum_size = Vector2(680, 408)
	weapon_choice_panel.add_child(box)

	var title := Label.new()
	title.text = "发现武器"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", INK_THEME.GOLD)
	box.add_child(title)

	weapon_choice_label = RichTextLabel.new()
	weapon_choice_label.bbcode_enabled = true
	weapon_choice_label.fit_content = false
	weapon_choice_label.scroll_active = false
	weapon_choice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weapon_choice_label.custom_minimum_size = Vector2(680, 288)
	weapon_choice_label.add_theme_font_size_override("normal_font_size", 14)
	box.add_child(weapon_choice_label)

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(680, 48)
	box.add_child(row)

	var replace_button := Button.new()
	replace_button.text = "替换当前武器"
	replace_button.custom_minimum_size = Vector2(212, 44)
	replace_button.pressed.connect(_accept_pending_weapon)
	row.add_child(replace_button)

	var keep_button := Button.new()
	keep_button.text = "保留当前武器"
	keep_button.custom_minimum_size = Vector2(212, 44)
	keep_button.pressed.connect(_decline_pending_weapon)
	row.add_child(keep_button)


func _build_shop_ui() -> void:
	shop_panel = Panel.new()
	shop_panel.visible = false
	shop_panel.position = Vector2(280, 78)
	shop_panel.size = Vector2(720, 562)
	shop_panel.custom_minimum_size = Vector2(720, 562)
	shop_panel.theme = ui_theme
	ui_layer.add_child(shop_panel)

	var box := VBoxContainer.new()
	box.position = Vector2(18, 16)
	box.size = Vector2(684, 530)
	box.custom_minimum_size = Vector2(684, 530)
	shop_panel.add_child(box)

	var title := Label.new()
	title.text = "卦摊货品"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", INK_THEME.GOLD)
	box.add_child(title)

	var hint := Label.new()
	hint.text = "选择货品购买，出售背包遗物换取灵石"
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.76, 0.73, 0.66))
	box.add_child(hint)

	shop_goods_box = VBoxContainer.new()
	shop_goods_box.custom_minimum_size = Vector2(684, 208)
	box.add_child(shop_goods_box)

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(684, 42)
	box.add_child(row)

	var refresh_button := Button.new()
	refresh_button.text = "刷新货品 20"
	refresh_button.custom_minimum_size = Vector2(140, 38)
	refresh_button.pressed.connect(_refresh_shop_paid)
	row.add_child(refresh_button)

	var close_button := Button.new()
	close_button.text = "收起卦摊"
	close_button.custom_minimum_size = Vector2(128, 38)
	close_button.pressed.connect(func() -> void: shop_panel.visible = false)
	row.add_child(close_button)

	var sell_title := Label.new()
	sell_title.text = "背包出售"
	sell_title.add_theme_font_size_override("font_size", 16)
	box.add_child(sell_title)

	shop_sell_grid = GridContainer.new()
	shop_sell_grid.columns = 4
	shop_sell_grid.custom_minimum_size = Vector2(684, 102)
	box.add_child(shop_sell_grid)

	shop_detail_label = RichTextLabel.new()
	shop_detail_label.bbcode_enabled = true
	shop_detail_label.fit_content = false
	shop_detail_label.scroll_active = false
	shop_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_detail_label.custom_minimum_size = Vector2(684, 78)
	shop_detail_label.add_theme_font_size_override("normal_font_size", 13)
	box.add_child(shop_detail_label)


func _build_settlement_ui() -> void:
	settlement_panel = Panel.new()
	settlement_panel.visible = false
	settlement_panel.position = Vector2(342, 154)
	settlement_panel.size = Vector2(596, 372)
	settlement_panel.custom_minimum_size = Vector2(596, 372)
	settlement_panel.theme = ui_theme
	ui_layer.add_child(settlement_panel)

	var box := VBoxContainer.new()
	box.position = Vector2(22, 20)
	box.size = Vector2(552, 332)
	box.custom_minimum_size = Vector2(552, 332)
	settlement_panel.add_child(box)

	var title := Label.new()
	title.text = "层间结算"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", INK_THEME.GOLD)
	box.add_child(title)

	settlement_label = RichTextLabel.new()
	settlement_label.bbcode_enabled = true
	settlement_label.fit_content = false
	settlement_label.scroll_active = false
	settlement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settlement_label.custom_minimum_size = Vector2(552, 234)
	settlement_label.add_theme_font_size_override("normal_font_size", 15)
	box.add_child(settlement_label)

	var next_button := Button.new()
	next_button.text = "进入下一层"
	next_button.custom_minimum_size = Vector2(160, 44)
	next_button.pressed.connect(_continue_next_floor)
	box.add_child(next_button)


func _build_run_result_ui() -> void:
	run_result_panel = Panel.new()
	run_result_panel.visible = false
	run_result_panel.position = Vector2(342, 146)
	run_result_panel.size = Vector2(596, 392)
	run_result_panel.custom_minimum_size = Vector2(596, 392)
	run_result_panel.theme = ui_theme
	ui_layer.add_child(run_result_panel)

	var box := VBoxContainer.new()
	box.position = Vector2(22, 20)
	box.size = Vector2(552, 352)
	box.custom_minimum_size = Vector2(552, 352)
	run_result_panel.add_child(box)

	run_result_title = Label.new()
	run_result_title.text = "本局结算"
	run_result_title.add_theme_font_size_override("font_size", 24)
	run_result_title.add_theme_color_override("font_color", INK_THEME.GOLD)
	box.add_child(run_result_title)

	run_result_label = RichTextLabel.new()
	run_result_label.bbcode_enabled = true
	run_result_label.fit_content = false
	run_result_label.scroll_active = false
	run_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	run_result_label.custom_minimum_size = Vector2(552, 250)
	run_result_label.add_theme_font_size_override("normal_font_size", 15)
	box.add_child(run_result_label)

	var restart_button := Button.new()
	restart_button.text = "重新开始"
	restart_button.custom_minimum_size = Vector2(160, 44)
	restart_button.pressed.connect(_start_game)
	box.add_child(restart_button)


func _start_game() -> void:
	menu_control.visible = false
	if run_result_panel != null:
		run_result_panel.visible = false
	if settlement_panel != null:
		settlement_panel.visible = false
	if shop_panel != null:
		shop_panel.visible = false
	state = "prep"
	current_floor = 1
	run_seed = randi_range(100000, 999999)
	telemetry.reset(run_seed)
	var initial_player := {
		"pos": Vector2(ARENA.get_center()),
		"hp": 100.0,
		"max_hp": 100.0,
		"speed": 230.0,
		"base_speed": 230.0,
		"damage": 10.0,
		"combo": 0,
		"combo_expire": 0.0,
		"attack_cd": 0.0,
		"subskill_cd": 0.0,
		"dodge_cd": 0.0,
		"anim_action": "idle",
		"anim_time": 0.0,
		"anim_duration": 0.0,
		"loop_action": "idle",
		"loop_clock": 0.0,
		"haste_time": 0.0,
		"guard_time": 0.0,
		"rage_time": 0.0,
		"yuan_pulse_cd": 10.0,
		"stones": 0,
		"karma": 0,
		"weapon": weapons[0].duplicate(true),
		"inventory": [relics[0], relics[3], relics[5]],
		"disk": [null, null, null, null, null],
		"lore_seen": {},
		"state": "normal",
		"dir": Vector2.RIGHT,
		"facing_right": true,
		"stats": {},
		"patterns": [],
		"combos": [],
		"invuln": 0.0,
		"hurt": 0.0,
		"haste": 0.0,
		"guard": 0.0,
		"rage": 0.0,
		"radius": 12.0,
		"facing": 0.0,
	}
	player_module.setup(initial_player)
	enemy_module.clear()
	relic_module.setup(relics, [relics[0], relics[3], relics[5]])
	disk_module.setup([null, null, null, null, null])
	combat_feedback_module.clear_all()
	debug_anchor_targets.clear()
	slash = {}
	boss_portal = {}
	boss_started_at = 0
	_generate_map()
	_evaluate_build()
	_validate_player()
	_show_message("备战房间：WASD移动，J/鼠标攻击，Space闪避，Tab打开五行盘。靠近门按E出发。", 5.0)


func _process(delta: float) -> void:
	combat_feedback_module.update(delta)
	var in_hit_stop: bool = combat_feedback_module.get_hit_stop_time() > 0.0
	if state != "menu":
		player_module.update_timers(delta)
	if in_hit_stop:
		queue_redraw()
		return
	animation_clock += delta

	if drag_sprite != null and drag_relic != null:
		drag_sprite.position = get_global_mouse_position() - Vector2(36, 27)
		_update_drag_preview()
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_drop_drag()

	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0:
			message_label.visible = false

	if state != "menu":
		player_module.update_timers(delta)
		player_module.move(delta)
		if state == "combat":
			enemy_module.update_combat(delta)
	_update_effects(delta)
	queue_redraw()
	emit_signal("process_frame")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_F6, KEY_6] and OS.is_debug_build():
		_debug_anchor_review()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_F7, KEY_7] and OS.is_debug_build():
		_debug_vfx_lifecycle_review()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_F8, KEY_8] and OS.is_debug_build():
		_debug_animation_review()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_F9, KEY_9] and OS.is_debug_build():
		_debug_art_showcase()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10 and OS.is_debug_build():
		_debug_enter_boss()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11 and OS.is_debug_build():
		_debug_force_boss_phase_two()
		return
	if state == "menu":
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		player_module.attack(get_global_mouse_position(), true)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		player_module.use_subskill(get_global_mouse_position())
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and drag_relic != null:
		_drop_drag()
	if event.is_action_pressed("attack"):
		player_module.attack(get_global_mouse_position(), true)
	if event.is_action_pressed("dodge"):
		player_module.dodge()
	if event.is_action_pressed("interact"):
		_interact()
	if event.is_action_pressed("disk") or event.is_action_pressed("inventory"):
		_toggle_disk(not disk_panel.visible)
	if event.is_action_pressed("map"):
		_show_message("右上角为当前迷宫：起/战/精/商/王。已清理房间会变暗。", 2.5)
	if event.is_action_pressed("restart"):
		_start_game()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_shop_buy(1)
		elif event.keycode == KEY_2:
			_shop_buy(2)
		elif event.keycode == KEY_3:
			_shop_buy(3)
		elif event.keycode == KEY_4:
			_shop_buy(4)


func _debug_enter_boss() -> void:
	if state == "menu":
		_start_game()
	for i in rooms.size():
		if rooms[i]["type"] == "BOSS":
			_enter_room(i)
			player["invuln"] = 999.0
			_show_message("调试直达：检查金甲将军前摇、护盾、石柱与阶段表现。", 2.6)
			return


func _debug_art_showcase() -> void:
	if state == "menu":
		_start_game()
	state = "combat"
	enemies.clear()
	drops.clear()
	boss_pillars.clear()
	boss_hazards.clear()
	player["pos"] = ARENA.get_center() + Vector2(0, 160)
	player["invuln"] = 30.0
	_spawn_enemy("blade", ARENA.get_center() + Vector2(-245, -96))
	_spawn_enemy("guard", ARENA.get_center() + Vector2(-82, -96))
	_spawn_enemy("dart", ARENA.get_center() + Vector2(82, -96))
	_spawn_enemy("elite", ARENA.get_center() + Vector2(245, -96))
	for enemy in enemies:
		enemy["speed"] = 0.0
		enemy["damage"] = 0.0
		enemy["attack_cd"] = 999.0
	_show_message("调试美术场：刀灵、铜甲、镖手与金甲将。", 2.6)


func _debug_animation_review() -> void:
	if state == "menu":
		_start_game()
		await process_frame
	state = "combat"
	enemies.clear()
	drops.clear()
	boss_pillars.clear()
	boss_hazards.clear()
	player["pos"] = ARENA.get_center() + Vector2(0, 160)
	player["invuln"] = 30.0
	animation_clock = 0.0
	var review_duration := 2.4
	player["anim_action"] = "attack"
	player["anim_time"] = review_duration
	player["anim_duration"] = review_duration
	slash = {
		"pos": player["pos"],
		"angle": 0.0,
		"range": 112.0,
		"ttl": review_duration,
		"duration": review_duration,
		"combo": 3,
	}
	_spawn_sequence_vfx("crit", ARENA.get_center() + Vector2(-210.0, 54.0), 176.0, 0.0, review_duration)
	_spawn_sequence_vfx("fire", ARENA.get_center() + Vector2(210.0, 54.0), 176.0, 0.0, review_duration)
	_show_message("逐帧审阅：角色单帧交接；刀光与能量特效仅在帧尾短融合。", review_duration)


func _debug_anchor_review() -> void:
	if state == "menu":
		_start_game()
	state = "prep"
	impact_effects.clear()
	enemies.clear()
	var center := ARENA.get_center()
	var relic_target := center + Vector2(-250.0, -105.0)
	var harmony_target := center + Vector2(0.0, -105.0)
	var player_target := center + Vector2(250.0, -105.0)
	player["pos"] = player_target
	player["anim_action"] = "idle"
	player["anim_time"] = 0.0
	player["loop_action"] = "idle"
	player["loop_clock"] = 0.0
	_spawn_enemy("guard", center + Vector2(-145.0, 105.0))
	_spawn_enemy("elite", center + Vector2(145.0, 105.0))
	for enemy in enemies:
		enemy["damage"] = 0.0
		enemy["attack_cd"] = 999.0
		enemy["loop_clock"] = 0.0
	impact_effects.append({"kind": "relic_get", "pos": relic_target, "size": 214.0, "angle": 0.0, "ttl": 3.2, "duration": 3.2, "stretch": Vector2.ONE})
	impact_effects.append({"kind": "harmony", "pos": harmony_target, "size": 258.0, "angle": 0.0, "ttl": 3.2, "duration": 3.2, "stretch": Vector2.ONE})
	impact_effects.append({"kind": "frost_armor", "pos": player_target, "size": 222.0, "angle": 0.0, "ttl": 3.2, "duration": 3.2, "stretch": Vector2.ONE})
	debug_anchor_targets = [relic_target, harmony_target, player_target, enemies[0]["pos"], enemies[1]["pos"]]
	_show_message("锚点审阅：十字为逻辑目标；获得、圆满、护体与角色脚点应精确重合。", 4.0)


func _debug_vfx_lifecycle_review() -> void:
	if state == "menu":
		_start_game()
	state = "prep"
	player["pos"] = ARENA.get_center()
	impact_effects.clear()
	debug_anchor_targets.clear()
	var review_duration := 2.4
	_spawn_sequence_vfx("relic_get", player["pos"], 214.0, 0.0, review_duration)
	_spawn_sequence_vfx("weapon_get", player["pos"], 224.0, 0.0, review_duration)
	_spawn_sequence_vfx("pattern_high", player["pos"], 258.0, 0.0, review_duration)
	_show_message("VFX生命周期审阅：拾取/激活特效共用重启槽位，连续触发只保留最后一条。", 5.0)


func _debug_force_boss_phase_two() -> void:
	for i in enemies.size():
		if enemies[i].get("kind", "") != "boss":
			continue
		player["hp"] = player["max_hp"]
		player["invuln"] = 999.0
		disk_panel.visible = false
		enemies[i]["shield"] = 0.0
		enemies[i]["hp"] = enemies[i]["max_hp"] * 0.49
		enemies[i]["phase_changed"] = false
		_update_boss(i, 0.0)
		_show_message("调试切换：第二阶段木属性与藤蔓强化。", 2.4)
		return


func _update_player_timers(delta: float) -> void:
	player["attack_cd"] = maxf(0.0, player["attack_cd"] - delta)
	player["subskill_cd"] = maxf(0.0, player["subskill_cd"] - delta)
	player["dodge_cd"] = maxf(0.0, player["dodge_cd"] - delta)
	player["invuln"] = maxf(0.0, player["invuln"] - delta)
	player["hurt"] = maxf(0.0, player["hurt"] - delta)
	player["haste"] = maxf(0.0, player["haste"] - delta)
	player["guard"] = maxf(0.0, player["guard"] - delta)
	player["rage"] = maxf(0.0, player["rage"] - delta)
	if player["anim_time"] > 0.0:
		player["anim_time"] = maxf(0.0, player["anim_time"] - delta)
		if player["anim_time"] <= 0.0 and player["anim_action"] != "dead":
			player["anim_action"] = "idle"
	var stats: Dictionary = player["stats"]
	if stats.get("regen", 0.0) > 0.0 and stats.get("no_regen", 0.0) <= 0.0:
		player["hp"] = minf(player["max_hp"], player["hp"] + stats["regen"] * delta)
	if state == "combat" and stats.get("yuan_pulse", 0.0) > 0.0:
		player["yuan_pulse_cd"] = maxf(0.0, player["yuan_pulse_cd"] - delta)
		if player["yuan_pulse_cd"] <= 0.0:
			player["yuan_pulse_cd"] = 10.0
			_trigger_yuan_pulse()
	else:
		player["yuan_pulse_cd"] = minf(player["yuan_pulse_cd"], 10.0)


func _movement_dir() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		dir.x += 1.0
	if Input.is_action_pressed("move_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("move_down"):
		dir.y += 1.0
	if Input.is_action_pressed("move_up"):
		dir.y -= 1.0
	return dir.normalized() if dir.length_squared() > 0.0 else Vector2.ZERO


func _move_player(delta: float) -> void:
	if state in ["dead", "victory"]:
		return
	var dir := _movement_dir()
	var pos: Vector2 = player["pos"]
	if dir != Vector2.ZERO and player["hurt"] <= 0.0:
		var terrain_speed := 0.58 if _player_in_slow_hazard() else 1.0
		pos += dir * player["speed"] * terrain_speed * delta
		pos.x = clampf(pos.x, ARENA.position.x + player["radius"], ARENA.end.x - player["radius"])
		pos.y = clampf(pos.y, ARENA.position.y + player["radius"], ARENA.end.y - player["radius"])
		pos = _resolve_pillar_collision(pos, player["radius"])
		player["pos"] = pos
		player["facing"] = dir.angle()
		if player["anim_time"] <= 0.0:
			_advance_player_loop("run", delta)
	else:
		player["facing"] = (get_global_mouse_position() - pos).angle()
		if player["anim_time"] <= 0.0 and player["anim_action"] != "dead":
			_advance_player_loop("idle", delta)


func _advance_player_loop(action: String, delta: float) -> void:
	if player.get("loop_action", "idle") != action:
		player["loop_action"] = action
		player["loop_clock"] = 0.0
	else:
		player["loop_clock"] = player.get("loop_clock", 0.0) + delta
	player["anim_action"] = action


func _set_player_animation(action: String, duration: float) -> void:
	player["anim_action"] = action
	player["anim_time"] = duration
	player["anim_duration"] = duration


func _resolve_pillar_collision(pos: Vector2, radius: float) -> Vector2:
	var resolved := pos
	for pillar in boss_pillars:
		var offset: Vector2 = resolved - pillar["pos"]
		var min_distance: float = radius + pillar["radius"]
		if offset.length_squared() < min_distance * min_distance:
			var normal := offset.normalized() if offset.length_squared() > 0.1 else Vector2.RIGHT
			resolved = pillar["pos"] + normal * min_distance
	return resolved


func _generate_map() -> void:
	rooms.clear()
	for y in MAP_ROWS:
		for x in MAP_COLS:
			rooms.append({"x": x, "y": y, "type": "empty", "visited": false, "cleared": false, "links": []})

	var y := int(MAP_ROWS / 2)
	var start_idx := _room_index(0, y)
	rooms[start_idx]["type"] = "START"
	current_room = start_idx

	for x in range(MAP_COLS - 1):
		var cur_idx := _room_index(x, y)
		var next_y := clampi(y + [-1, 0, 1].pick_random(), 0, MAP_ROWS - 1)
		var next_idx := _room_index(x + 1, next_y)
		_link_rooms(cur_idx, next_idx)
		if rooms[next_idx]["type"] == "empty":
			rooms[next_idx]["type"] = "BOSS" if x + 1 == MAP_COLS - 1 else "MONSTER"
		y = next_y

	for i in 9:
		var filled := _filled_room_indices(false)
		if filled.is_empty():
			continue
		var base: int = filled.pick_random()
		var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		var d: Vector2i = dirs.pick_random()
		var nx := clampi(rooms[base]["x"] + d.x, 0, MAP_COLS - 1)
		var ny := clampi(rooms[base]["y"] + d.y, 0, MAP_ROWS - 1)
		var ni := _room_index(nx, ny)
		if rooms[ni]["type"] == "empty":
			rooms[ni]["type"] = "SHOP" if randf() < 0.12 else ("ELITE" if randf() < 0.28 else "MONSTER")
			_link_rooms(base, ni)

	var content := _filled_room_indices(true)
	if content.size() > 2:
		rooms[content[2]]["type"] = "SHOP"
	if content.size() > 5:
		rooms[content[5]]["type"] = "ELITE"

	rooms[current_room]["visited"] = true
	_enter_room(current_room)


func _room_index(x: int, y: int) -> int:
	return y * MAP_COLS + x


func _link_rooms(a: int, b: int) -> void:
	if not rooms[a]["links"].has(b):
		rooms[a]["links"].append(b)
	if not rooms[b]["links"].has(a):
		rooms[b]["links"].append(a)


func _filled_room_indices(exclude_start_boss: bool) -> Array[int]:
	var list: Array[int] = []
	for i in rooms.size():
		var t: String = rooms[i]["type"]
		if t == "empty":
			continue
		if exclude_start_boss and (t == "START" or t == "BOSS"):
			continue
		list.append(i)
	return list


func _enter_room(index: int) -> void:
	current_room = index
	rooms[index]["visited"] = true
	telemetry.record("room_enter", {"floor": current_floor, "room": index, "type": rooms[index]["type"]})
	room_entered.emit(index, rooms[index]["type"])
	enemies.clear()
	death_actors.clear()
	projectiles.clear()
	drops.clear()
	boss_pillars.clear()
	boss_hazards.clear()
	boss_portal = {}
	if shop_panel != null:
		shop_panel.visible = false
	if settlement_panel != null:
		settlement_panel.visible = false
	if run_result_panel != null:
		run_result_panel.visible = false
	player["pos"] = ARENA.get_center()
	var room_type: String = rooms[index]["type"]
	if room_type == "START":
		rooms[index]["cleared"] = true
		state = "prep" if state == "prep" else "explore"
		_show_message("START房：墨痕未干，前路已经显形。靠近出口按E进入相邻房间。", 3.2)
	elif room_type == "SHOP":
		state = "shop"
		if not rooms[index].has("shop_stock") or rooms[index]["shop_stock"].is_empty():
			rooms[index]["shop_stock"] = _generate_shop_stock()
		shop_stock = rooms[index]["shop_stock"]
		_refresh_shop_ui()
		shop_panel.visible = true
		_show_message("卦摊：挑选货品，或出售背包遗物。靠近门按E离开。", 4.0)
	elif rooms[index]["cleared"]:
		state = "explore"
		_show_message("旧径已清，墨门仍通向其他秘境节点。", 1.8)
	else:
		state = "combat"
		_spawn_room(room_type)


func _spawn_room(room_type: String) -> void:
	if room_type == "BOSS":
		var min_boss_hp: float = player["max_hp"] * 0.30
		if player["hp"] < min_boss_hp:
			player["hp"] = min_boss_hp
			telemetry.record("boss_preheal", {"floor": current_floor, "hp": player["hp"]})
			_show_message("Boss房前调息：生命回复至30%。", 2.0)
		_spawn_boss_pillars(false)
		_spawn_enemy("boss", Vector2(ARENA.get_center().x, ARENA.position.y + 150.0))
		boss_started_at = Time.get_ticks_msec()
		telemetry.record("boss_start", {"floor": current_floor, "boss": "金甲将军"})
		if player["hp"] <= min_boss_hp:
			_show_message("Boss战：金甲将军。生命已保底至30%，观察前摇与石柱。", 4.5)
		else:
			_show_message("Boss战：金甲将军。观察蓄力前摇，利用石柱诱导冲刺撞击。", 4.5)
		return
	if room_type == "ELITE":
		_spawn_enemy("elite", Vector2(ARENA.get_center().x, ARENA.position.y + 160.0))
		_spawn_enemy(["blade", "guard", "dart"].pick_random(), Vector2(ARENA.get_center().x - 160.0, ARENA.position.y + 330.0))
		_show_message("精英房：击败金甲将保底掉落燕无归武器。", 3.0)
		return
	for i in randi_range(2, 4):
		_spawn_enemy(["blade", "guard", "dart"].pick_random(), Vector2(randf_range(ARENA.position.x + 90.0, ARENA.end.x - 90.0), randf_range(ARENA.position.y + 90.0, ARENA.end.y - 90.0)))


func _spawn_enemy(kind: String, pos: Vector2) -> void:
	var spec: Dictionary = enemy_specs[kind]
	var hp_scale := 1.0 + float(current_floor - 1) * 0.28
	var dmg_scale := 1.0 + float(current_floor - 1) * 0.15
	var stone_scale := 1.0 + float(current_floor - 1) * 0.20
	var enemy := {
		"kind": kind,
		"name": spec["name"],
		"pos": pos,
		"radius": spec["radius"],
		"hp": spec["hp"] * hp_scale,
		"max_hp": spec["hp"] * hp_scale,
		"damage": spec["damage"] * dmg_scale,
		"speed": spec["speed"],
		"ai": spec["ai"],
		"element": spec["element"],
		"stone": ceili(spec["stone"] * stone_scale),
		"attack_cd": randf_range(0.4, 1.2),
		"facing": (player["pos"] - pos).angle(),
		"anim_action": "idle",
		"anim_time": 0.0,
		"anim_duration": 0.0,
		"loop_action": "idle",
		"loop_clock": randf_range(0.0, 1.0),
		"moving": false,
		"hurt": 0.0,
		"slow": 0.0,
		"burn": 0.0,
		"burn_tick": 0.0,
	}
	if kind == "boss":
		enemy.merge({
			"shield": 100.0,
			"max_shield": 100.0,
			"phase": 1,
			"phase_changed": false,
			"boss_state": "recover",
			"boss_action": "",
			"boss_timer": 1.2,
			"sequence_index": 0,
			"charge_dir": Vector2.ZERO,
			"charge_hit_player": false,
			"telegraph_total": 0.0,
		})
	enemies.append(enemy)


func _attack(aim_pos: Vector2 = Vector2.ZERO, use_aim: bool = false) -> void:
	if state != "combat" or player["attack_cd"] > 0.0 or player["hurt"] > 0.0:
		return
	if use_aim:
		var aim_dir: Vector2 = aim_pos - player["pos"]
		if aim_dir.length_squared() > 4.0:
			player["facing"] = aim_dir.angle()
	var time := Time.get_ticks_msec() / 1000.0
	player["combo"] = int(player["combo"] % 3) + 1 if time < player["combo_expire"] else 1
	player["combo_expire"] = time + 2.5
	var weapon: Dictionary = player["weapon"]
	var combo_cd_scale := 0.92 if player["combo"] == 3 else 0.80
	player["attack_cd"] = (1.0 / (weapon["rate"] * ATTACK_RATE_MULT)) * combo_cd_scale
	if player["haste"] > 0.0:
		player["attack_cd"] *= 0.62
	var stats: Dictionary = player["stats"]
	var attack_range: float = weapon["range"] * (1.0 + stats.get("range", 0.0))
	if player["combo"] == 3:
		attack_range += 90.0 if weapon["id"] == "mohong" else 40.0
	var facing: float = player["facing"]
	var arc := PI * 0.72
	var crit_chance: float = 0.0 if stats.get("crit_disabled", 0.0) > 0.0 else 0.08 + stats.get("crit", 0.0)
	var crit: bool = randf() < crit_chance
	var mult: float = weapon["mult"] * (1.35 if player["combo"] == 3 else 1.0) * (1.7 if crit else 1.0)
	if player["rage"] > 0.0:
		mult *= 1.35
	var slash_duration := 0.26 if player["combo"] == 3 else 0.20
	slash = {"pos": player["pos"], "angle": facing, "range": attack_range, "ttl": slash_duration, "duration": slash_duration, "combo": player["combo"]}
	_set_player_animation("attack", slash_duration)

	var hit := false
	var player_pos: Vector2 = player["pos"]
	for i in range(enemies.size() - 1, -1, -1):
		var e := enemies[i]
		var to_enemy: Vector2 = e["pos"] - player_pos
		var delta := absf(angle_difference(facing, to_enemy.angle()))
		if to_enemy.length() <= attack_range + e["radius"] and delta <= arc * 0.5:
			hit = true
			_damage_enemy(i, player["damage"] * mult, crit, true)
			if i < enemies.size():
				enemies[i]["pos"] += Vector2.RIGHT.rotated(facing) * (88.0 if player["combo"] == 3 else 42.0)

	if weapon["id"] == "lieshan" and player["combo"] == 3:
		var shock_center: Vector2 = player_pos + Vector2.RIGHT.rotated(facing) * attack_range * 0.62
		for i in range(enemies.size() - 1, -1, -1):
			if enemies[i]["pos"].distance_to(shock_center) <= 148.0:
				hit = true
				_damage_enemy(i, player["damage"] * weapon["mult"] * 0.55, false, true)
		_spawn_ink(shock_center, 16, Color(0.32, 0.28, 0.22))

	if player["combo"] == 3:
		var dash := Vector2.RIGHT.rotated(facing) * 58.0
		var pos: Vector2 = player["pos"] + dash
		pos.x = clampf(pos.x, ARENA.position.x + player["radius"], ARENA.end.x - player["radius"])
		pos.y = clampf(pos.y, ARENA.position.y + player["radius"], ARENA.end.y - player["radius"])
		player["pos"] = pos

	if hit:
		_hit_stop(0.12 if crit else 0.06)
		_shake(9.0 if crit else 4.0, 0.22 if crit else 0.16)
		_spawn_ink(player_pos + Vector2.RIGHT.rotated(facing) * attack_range * 0.55, 18 if crit else 12, Color(0.95, 0.82, 0.48) if crit else Color(0.07, 0.07, 0.07))


func _dodge() -> void:
	if player["dodge_cd"] > 0.0 or player["hurt"] > 0.0 or state in ["dead", "victory"]:
		return
	var origin: Vector2 = player["pos"]
	var dir := _movement_dir()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT.rotated(player["facing"])
	var pos: Vector2 = player["pos"] + dir * 110.0
	pos.x = clampf(pos.x, ARENA.position.x + player["radius"], ARENA.end.x - player["radius"])
	pos.y = clampf(pos.y, ARENA.position.y + player["radius"], ARENA.end.y - player["radius"])
	pos = _resolve_pillar_collision(pos, player["radius"])
	player["pos"] = pos
	player["invuln"] = 0.5
	player["dodge_cd"] = maxf(0.55, 1.5 - player["stats"].get("cd", 0.0) + player["stats"].get("dodge_cd_add", 0.0))
	_set_player_animation("dodge", 0.34)
	_spawn_sequence_vfx("dodge", origin + dir * 55.0, 210.0, dir.angle(), 0.34, Vector2(1.18, 0.72))


func _use_subskill(aim_pos: Vector2) -> void:
	if state != "combat" or player["subskill_cd"] > 0.0 or player["hurt"] > 0.0:
		return
	var weapon: Dictionary = player["weapon"]
	var variant: Dictionary = weapon.get("variant", {})
	if variant.is_empty():
		_show_message("白板武器没有副技能。", 1.2)
		return
	var dir: Vector2 = _aim_direction(aim_pos)
	player["facing"] = dir.angle()
	player["subskill_cd"] = 5.5
	_set_player_animation("attack", 0.42)
	var damage: float = float(player["damage"]) * float(weapon.get("mult", 1.0))
	var center: Vector2 = player["pos"] + dir * 72.0
	match variant["id"]:
		"sword_wave":
			projectiles.append({"owner": "player", "pos": player["pos"] + dir * 28.0, "vel": dir * 560.0, "radius": 12.0, "damage": damage * 1.05, "ttl": 0.55, "duration": 0.55, "pierce": 3, "kind": "sword_wave"})
			_spawn_ink(player["pos"], 10, Color(0.80, 0.85, 0.88))
		"blink_slash":
			var blink_origin: Vector2 = player["pos"]
			_move_subskill(dir, 154.0)
			_set_player_animation("dodge", 0.34)
			_spawn_sequence_vfx("blink_slash", blink_origin + dir * 76.0, 246.0, dir.angle(), 0.36, Vector2(1.16, 0.76))
			_subskill_area_damage(player["pos"], 104.0, damage * 1.25, Color(0.86, 0.86, 0.84), true)
		"combo_haste":
			player["haste"] = 3.2
			_show_message("连环剑：攻速提升。", 1.4)
			_spawn_ink(player["pos"], 16, Color(0.86, 0.86, 0.84))
			_spawn_sequence_vfx("combo_haste", player["pos"], 224.0, 0.0, 0.52)
		"ice_scar":
			var hits: int = _subskill_area_damage(center, 118.0, damage * 0.9, ELEMENT_COLORS["water"], true)
			_spawn_sequence_vfx("ice_scar", center, 242.0, dir.angle(), 0.42, Vector2(1.12, 0.78))
			_slow_near(center, 136.0, 2.8)
			_show_message("冰痕斩：命中%d个目标。" % hits, 1.2)
		"cold_flash":
			var cold_origin: Vector2 = player["pos"]
			_move_subskill(dir, 118.0)
			_set_player_animation("dodge", 0.32)
			_spawn_sequence_vfx("cold_flash", cold_origin + dir * 62.0, 238.0, dir.angle(), 0.36, Vector2(1.20, 0.72))
			_subskill_area_damage(player["pos"], 118.0, damage, ELEMENT_COLORS["water"], true)
			_slow_near(player["pos"], 138.0, 2.4)
		"frost_armor":
			player["guard"] = 3.5
			player["subskill_cd"] = 7.0
			_show_message("霜甲：短暂减伤。", 1.4)
			_spawn_ink(player["pos"], 18, ELEMENT_COLORS["water"])
			_spawn_sequence_vfx("frost_armor", player["pos"], 232.0, 0.0, 0.58)
		"rainbow_cut":
			projectiles.append({"owner": "player", "pos": player["pos"] + dir * 28.0, "vel": dir * 680.0, "radius": 15.0, "damage": damage * 1.20, "ttl": 0.48, "duration": 0.48, "pierce": 4, "kind": "rainbow_cut"})
			_spawn_ink(player["pos"], 14, Color(0.62, 0.55, 0.90))
		"ink_shadow":
			var shadow_pos: Vector2 = player["pos"]
			_move_subskill(-dir, 80.0)
			_set_player_animation("dodge", 0.34)
			_spawn_sequence_vfx("ink_shadow", shadow_pos + dir * 42.0, 246.0, dir.angle(), 0.44, Vector2(1.16, 0.76))
			_subskill_area_damage(shadow_pos, 128.0, damage * 1.05, Color(0.08, 0.08, 0.08), true)
		"return_blade":
			projectiles.append({"owner": "player", "pos": player["pos"] + dir * 28.0, "vel": dir * 520.0, "radius": 13.0, "damage": damage * 0.85, "ttl": 0.38, "duration": 0.38, "pierce": 2, "kind": "return_blade"})
			projectiles.append({"owner": "player", "pos": player["pos"] + dir * 230.0, "vel": -dir * 520.0, "radius": 13.0, "damage": damage * 0.85, "ttl": 0.38, "duration": 0.38, "pierce": 2, "kind": "return_blade"})
		"mountain_cleave":
			_subskill_area_damage(center, 154.0, damage * 1.35, ELEMENT_COLORS["earth"], true)
			_spawn_sequence_vfx("mountain_cleave", center, 312.0, dir.angle(), 0.48)
			_shake(8.0, 0.20)
		"earth_quake":
			_subskill_area_damage(player["pos"], 174.0, damage * 0.95, ELEMENT_COLORS["earth"], true)
			_spawn_sequence_vfx("earth_quake", player["pos"], 352.0, 0.0, 0.54)
			_knockback_near(player["pos"], 184.0, 74.0)
			_shake(10.0, 0.22)
		"iron_wall":
			player["guard"] = 3.0
			player["subskill_cd"] = 7.0
			_knockback_near(player["pos"], 132.0, 88.0)
			_spawn_sequence_vfx("iron_wall", player["pos"] + dir * 28.0, 276.0, dir.angle(), 0.56)
			_show_message("铁壁斩：减伤并震退近敌。", 1.4)
		"blood_rage":
			player["hp"] = maxf(1.0, player["hp"] - 8.0)
			player["rage"] = 4.0
			_show_message("血怒：消耗生命提升伤害。", 1.4)
			_spawn_ink(player["pos"], 18, Color(0.72, 0.16, 0.16))
			_spawn_sequence_vfx("blood_rage", player["pos"], 238.0, 0.0, 0.58)
		"soul_bite":
			var hits: int = _subskill_area_damage(center, 128.0, damage * 1.05, Color(0.64, 0.18, 0.22), true)
			_spawn_sequence_vfx("soul_bite", center, 254.0, dir.angle(), 0.46, Vector2(1.14, 0.82))
			if hits > 0:
				player["hp"] = minf(player["max_hp"], player["hp"] + 5.0 * hits)
			_show_message("噬魂斩：吸取%d个目标。" % hits, 1.3)
		"blood_shield":
			player["hp"] = maxf(1.0, player["hp"] - 6.0)
			player["guard"] = 4.0
			player["subskill_cd"] = 7.5
			_show_message("血盾：生命换取防护。", 1.4)
			_spawn_ink(player["pos"], 20, Color(0.72, 0.16, 0.16))
			_spawn_sequence_vfx("blood_shield", player["pos"], 242.0, 0.0, 0.60)
	_hit_stop(0.04)


func _aim_direction(aim_pos: Vector2) -> Vector2:
	var dir: Vector2 = aim_pos - player["pos"]
	if dir.length_squared() <= 4.0:
		return Vector2.RIGHT.rotated(player["facing"])
	return dir.normalized()


func _move_subskill(dir: Vector2, distance: float) -> void:
	var pos: Vector2 = player["pos"] + dir * distance
	pos.x = clampf(pos.x, ARENA.position.x + player["radius"], ARENA.end.x - player["radius"])
	pos.y = clampf(pos.y, ARENA.position.y + player["radius"], ARENA.end.y - player["radius"])
	player["pos"] = _resolve_pillar_collision(pos, player["radius"])
	player["invuln"] = maxf(player["invuln"], 0.18)


func _subskill_area_damage(center: Vector2, radius: float, amount: float, ink_color: Color, apply_on_hit: bool) -> int:
	var hits := 0
	_spawn_ink(center, 18, ink_color)
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i]["pos"].distance_to(center) <= radius + enemies[i]["radius"]:
			hits += 1
			_damage_enemy(i, amount, false, apply_on_hit)
	return hits


func _slow_near(center: Vector2, radius: float, seconds: float) -> void:
	for i in range(enemies.size()):
		if enemies[i]["pos"].distance_to(center) <= radius + enemies[i]["radius"]:
			enemies[i]["slow"] = maxf(enemies[i]["slow"], seconds)


func _knockback_near(center: Vector2, radius: float, distance: float) -> void:
	for i in range(enemies.size()):
		var offset: Vector2 = enemies[i]["pos"] - center
		if offset.length() <= radius + enemies[i]["radius"]:
			var dir := offset.normalized() if offset.length_squared() > 0.1 else Vector2.RIGHT
			enemies[i]["pos"] += dir * distance


func _trigger_yuan_pulse() -> void:
	if not player["patterns"].has("五行圆满"):
		return
	player["hp"] = minf(player["max_hp"], player["hp"] + player["max_hp"] * 0.03)
	_apply_area_damage(player["pos"], 999.0, player["damage"] * 0.55, Color(0.85, 0.70, 0.36))
	_spawn_ink(player["pos"], 28, Color(0.85, 0.70, 0.36))
	_spawn_sequence_vfx("harmony", player["pos"], 328.0, 0.0, 0.62)
	_show_message("五行圆满：归元脉冲。", 1.2)


func _update_combat(delta: float) -> void:
	var player_pos: Vector2 = player["pos"]
	for i in range(enemies.size() - 1, -1, -1):
		if i >= enemies.size():
			continue
		var e := enemies[i]
		e["hurt"] = maxf(0.0, e["hurt"] - delta)
		e["slow"] = maxf(0.0, e["slow"] - delta)
		e["moving"] = false
		if e["anim_time"] > 0.0:
			e["anim_time"] = maxf(0.0, e["anim_time"] - delta)
		if e["burn"] > 0.0:
			e["burn"] -= delta
			e["burn_tick"] -= delta
			if e["burn_tick"] <= 0.0:
				e["burn_tick"] = 0.5
				_damage_enemy(i, 4.0 * (1.0 + player["stats"].get("burn_power", 0.0)), false, false)
				continue

		if i >= enemies.size():
			continue
		e = enemies[i]
		if e["ai"] == "boss":
			_update_boss(i, delta)
			if i < enemies.size():
				_advance_enemy_loop(enemies[i], delta)
			continue
		var to_player: Vector2 = player_pos - e["pos"]
		var distance := maxf(1.0, to_player.length())
		var dir := to_player / distance
		e["facing"] = dir.angle()
		var speed_mult := 0.45 if e["slow"] > 0.0 else 1.0
		e["attack_cd"] -= delta

		if e["ai"] == "ranged" and distance < 250.0:
			e["pos"] -= dir * e["speed"] * 0.55 * delta
			e["moving"] = true
		elif e["ai"] != "boss" or distance > 80.0:
			e["pos"] += dir * e["speed"] * speed_mult * delta
			e["moving"] = true
		e["pos"] = Vector2(
			clampf(e["pos"].x, ARENA.position.x + e["radius"], ARENA.end.x - e["radius"]),
			clampf(e["pos"].y, ARENA.position.y + e["radius"], ARENA.end.y - e["radius"])
		)

		if e["ai"] == "ranged" and e["attack_cd"] <= 0.0:
			projectiles.append({"pos": e["pos"], "vel": dir * 280.0, "radius": 6.0, "damage": e["damage"], "ttl": 3.0})
			e["anim_action"] = "attack"
			e["anim_time"] = 0.42
			e["anim_duration"] = 0.42
			e["attack_cd"] = 1.8
		elif distance < e["radius"] + player["radius"] + 6.0 and e["attack_cd"] <= 0.0:
			_damage_player(e["damage"])
			e["anim_action"] = "attack"
			e["anim_time"] = 0.38
			e["anim_duration"] = 0.38
			e["attack_cd"] = 1.05 if e["ai"] == "boss" else 1.2
		_advance_enemy_loop(e, delta)

	for i in range(projectiles.size() - 1, -1, -1):
		var p := projectiles[i]
		p["pos"] += p["vel"] * delta
		p["ttl"] -= delta
		var blocked := false
		for pillar in boss_pillars:
			if p["pos"].distance_to(pillar["pos"]) <= p["radius"] + pillar["radius"]:
				blocked = true
				break
		if blocked:
			_spawn_ink(p["pos"], 7, Color(0.50, 0.47, 0.40))
			projectiles.remove_at(i)
			continue
		if p.get("owner", "enemy") == "player":
			var consumed := false
			for enemy_index in range(enemies.size() - 1, -1, -1):
				if enemies[enemy_index]["pos"].distance_to(p["pos"]) <= enemies[enemy_index]["radius"] + p["radius"]:
					_damage_enemy(enemy_index, p["damage"], false, true)
					p["pierce"] = int(p.get("pierce", 1)) - 1
					consumed = p["pierce"] <= 0
					break
			if consumed:
				_spawn_ink(p["pos"], 8, Color(0.86, 0.82, 0.72))
				projectiles.remove_at(i)
			elif p["ttl"] <= 0.0:
				projectiles.remove_at(i)
		elif p["pos"].distance_to(player_pos) < p["radius"] + player["radius"]:
			_damage_player(p["damage"])
			projectiles.remove_at(i)
		elif p["ttl"] <= 0.0:
			projectiles.remove_at(i)

	_update_boss_hazards(delta)


func _advance_enemy_loop(enemy: Dictionary, delta: float) -> void:
	if enemy.get("anim_time", 0.0) > 0.0 or enemy.get("hurt", 0.0) > 0.0:
		return
	var action := "run" if enemy.get("moving", false) else "idle"
	if enemy.get("loop_action", "idle") != action:
		enemy["loop_action"] = action
		enemy["loop_clock"] = 0.0
	else:
		enemy["loop_clock"] = enemy.get("loop_clock", 0.0) + delta


func _spawn_boss_pillars(phase_two: bool) -> void:
	boss_pillars.clear()
	var center := ARENA.get_center()
	var offsets := [Vector2(-150, 0), Vector2(150, 0), Vector2(0, -130), Vector2(0, 130)]
	if phase_two:
		offsets = [Vector2(-190, -105), Vector2(190, -105), Vector2(-190, 105), Vector2(190, 105)]
	for offset in offsets:
		boss_pillars.append({"pos": center + offset, "radius": 25.0, "hp": 1})


func _update_boss(index: int, delta: float) -> void:
	if index < 0 or index >= enemies.size():
		return
	var boss: Dictionary = enemies[index]
	boss["moving"] = false
	if boss["hp"] <= boss["max_hp"] * 0.5 and not boss["phase_changed"]:
		boss["phase_changed"] = true
		boss["phase"] = 2
		boss["element"] = "wood"
		boss["speed"] *= 1.2
		boss["boss_state"] = "recover"
		boss["boss_action"] = ""
		boss["boss_timer"] = 2.0
		boss["anim_action"] = "phase"
		boss["anim_time"] = 0.72
		boss["anim_duration"] = 0.72
		boss["sequence_index"] = 0
		boss_hazards.clear()
		_spawn_boss_pillars(true)
		_shake(13.0, 0.45)
		_spawn_ink(boss["pos"], 40, ELEMENT_COLORS["wood"])
		_spawn_sequence_vfx("wood", boss["pos"], 318.0, 0.0, 0.58)
		_show_message("金甲碎裂，木气破甲而出！新石柱升起，招式附带藤蔓。", 3.5)
		telemetry.record("boss_phase", {"floor": current_floor, "phase": 2, "hp": boss["hp"]})
		return

	boss["boss_timer"] -= delta
	match boss["boss_state"]:
		"recover":
			var to_player: Vector2 = player["pos"] - boss["pos"]
			if to_player.length() > 135.0:
				boss["pos"] += to_player.normalized() * boss["speed"] * 0.42 * delta
				boss["moving"] = true
			boss["facing"] = to_player.angle()
			if boss["boss_timer"] <= 0.0:
				_start_boss_action(boss)
		"telegraph":
			boss["facing"] = (player["pos"] - boss["pos"]).angle()
			if boss["boss_timer"] <= 0.0:
				_execute_boss_action(boss)
		"charge":
			_update_boss_charge(boss, delta)
		"stunned":
			if boss["boss_timer"] <= 0.0:
				_finish_boss_action(boss, 0.8)

	boss["pos"].x = clampf(boss["pos"].x, ARENA.position.x + boss["radius"], ARENA.end.x - boss["radius"])
	boss["pos"].y = clampf(boss["pos"].y, ARENA.position.y + boss["radius"], ARENA.end.y - boss["radius"])


func _start_boss_action(boss: Dictionary) -> void:
	var sequence: Array = BOSS_PHASE_ONE_SEQUENCE if boss["phase"] == 1 else BOSS_PHASE_TWO_SEQUENCE
	var action: String = sequence[boss["sequence_index"] % sequence.size()]
	boss["sequence_index"] += 1
	boss["boss_action"] = action
	boss["boss_state"] = "telegraph"
	boss["charge_hit_player"] = false
	boss["facing"] = (player["pos"] - boss["pos"]).angle()
	var telegraph := 1.0
	if action == "sweep":
		telegraph = 0.8
	elif action == "charge":
		telegraph = 0.5
	boss["boss_timer"] = telegraph
	boss["telegraph_total"] = telegraph
	boss["anim_action"] = "attack"
	boss["anim_time"] = telegraph
	boss["anim_duration"] = telegraph


func _execute_boss_action(boss: Dictionary) -> void:
	var action: String = boss["boss_action"]
	if action == "cleave":
		var to_player: Vector2 = player["pos"] - boss["pos"]
		if to_player.length() <= 200.0 and absf(angle_difference(boss["facing"], to_player.angle())) <= PI * 0.25:
			_boss_damage_if_exposed(boss["pos"], 24.0 if boss["phase"] == 2 else 20.0)
		_spawn_ink(boss["pos"] + Vector2.RIGHT.rotated(boss["facing"]) * 120.0, 22, ELEMENT_COLORS[boss["element"]])
		if boss["phase"] == 2:
			boss_hazards.append({"pos": boss["pos"] + Vector2.RIGHT.rotated(boss["facing"]) * 135.0, "radius": 62.0, "ttl": 4.0})
		_finish_boss_action(boss, 2.0)
	elif action == "sweep":
		if player["pos"].distance_to(boss["pos"]) <= 150.0:
			_boss_damage_if_exposed(boss["pos"], 22.0 if boss["phase"] == 2 else 18.0)
		_spawn_ink(boss["pos"], 30, ELEMENT_COLORS[boss["element"]])
		if boss["phase"] == 2:
			for spoke in 8:
				projectiles.append({"pos": boss["pos"], "vel": Vector2.RIGHT.rotated(float(spoke) * TAU / 8.0) * 230.0, "radius": 8.0, "damage": 12.0, "ttl": 2.2, "kind": "vine"})
		_finish_boss_action(boss, 1.5)
	else:
		boss["charge_dir"] = Vector2.RIGHT.rotated(boss["facing"])
		boss["boss_state"] = "charge"
		boss["boss_timer"] = 0.72


func _update_boss_charge(boss: Dictionary, delta: float) -> void:
	boss["moving"] = true
	var old_pos: Vector2 = boss["pos"]
	var step: Vector2 = boss["charge_dir"] * (555.0 if boss["phase"] == 1 else 665.0) * delta
	boss["pos"] += step
	if boss["phase"] == 2 and old_pos.distance_to(boss["pos"]) > 4.0:
		boss_hazards.append({"pos": boss["pos"], "radius": 28.0, "ttl": 3.5})
	for i in range(boss_pillars.size() - 1, -1, -1):
		if boss["pos"].distance_to(boss_pillars[i]["pos"]) <= boss["radius"] + boss_pillars[i]["radius"]:
			var pillar_pos: Vector2 = boss_pillars[i]["pos"]
			boss_pillars.remove_at(i)
			boss["pos"] = old_pos
			boss["boss_state"] = "stunned"
			boss["boss_timer"] = 2.5 if boss["phase"] == 1 else 1.5
			boss["boss_action"] = "撞柱眩晕"
			_spawn_ink(pillar_pos, 34, Color(0.53, 0.49, 0.40))
			_shake(14.0, 0.38)
			return
	if not boss["charge_hit_player"] and boss["pos"].distance_to(player["pos"]) <= boss["radius"] + player["radius"]:
		boss["charge_hit_player"] = true
		_damage_player(30.0 if boss["phase"] == 2 else 26.0)
	if boss["boss_timer"] <= 0.0 or not ARENA.grow(-boss["radius"]).has_point(boss["pos"]):
		_finish_boss_action(boss, 1.2)


func _finish_boss_action(boss: Dictionary, recovery: float) -> void:
	boss["boss_state"] = "recover"
	boss["boss_action"] = ""
	boss["boss_timer"] = recovery


func _boss_damage_if_exposed(origin: Vector2, amount: float) -> void:
	if not _line_blocked_by_pillar(origin, player["pos"]):
		_damage_player(amount)
	else:
		_add_text(player["pos"] + Vector2(0, -28), "石柱格挡", Color(0.84, 0.78, 0.65), 0.9)


func _line_blocked_by_pillar(origin: Vector2, target: Vector2) -> bool:
	var segment := target - origin
	var length_squared := segment.length_squared()
	if length_squared <= 1.0:
		return false
	for pillar in boss_pillars:
		var t: float = clampf((pillar["pos"] - origin).dot(segment) / length_squared, 0.0, 1.0)
		var closest := origin + segment * t
		if t > 0.08 and t < 0.92 and closest.distance_to(pillar["pos"]) <= pillar["radius"] + 5.0:
			return true
	return false


func _update_boss_hazards(delta: float) -> void:
	for i in range(boss_hazards.size() - 1, -1, -1):
		boss_hazards[i]["ttl"] -= delta
		if boss_hazards[i]["ttl"] <= 0.0:
			boss_hazards.remove_at(i)


func _player_in_slow_hazard() -> bool:
	for hazard in boss_hazards:
		if player["pos"].distance_to(hazard["pos"]) <= hazard["radius"] + player["radius"]:
			return true
	return false


func _damage_enemy(index: int, amount: float, crit: bool, apply_on_hit: bool) -> void:
	if index < 0 or index >= enemies.size():
		return
	var e := enemies[index]
	var stats: Dictionary = player["stats"]
	var damage: float = amount * (1.0 + stats.get("damage", 0.0) + stats.get("all", 0.0))
	if not crit:
		damage *= 1.0 + stats.get("noncrit_damage", 0.0)
	if e.get("ai", "") == "shielder" or e.get("kind", "") == "guard":
		damage *= 1.0 + stats.get("armor_damage", 0.0) + stats.get("armor_pierce", 0.0)
	if e.get("kind", "") == "boss" and e.get("shield", 0.0) > 0.0:
		var shield_multiplier := 2.0 if player["element_counts"].get("fire", 0) > 0 and e["element"] == "metal" else 1.0
		var shield_damage: float = damage * shield_multiplier
		e["shield"] = maxf(0.0, e["shield"] - shield_damage)
		e["hurt"] = 0.12
		if CHARACTER_SEQUENCES.has_action(e["kind"], "hurt"):
			e["anim_action"] = "hurt"
			e["anim_time"] = 0.0
			e["anim_duration"] = 0.12
		_add_text(e["pos"] + Vector2(0, -42), "盾 -%d" % roundi(shield_damage), ELEMENT_COLORS["metal"], 1.0)
		if e["shield"] <= 0.0:
			_spawn_ink(e["pos"], 32, ELEMENT_COLORS["metal"])
			_spawn_sequence_vfx("shield_break", e["pos"], 228.0, 0.0, 0.44)
			_shake(10.0, 0.28)
			_show_message("金甲护盾已破！金甲将军本体暴露。", 2.2)
		else:
			_spawn_sequence_vfx("metal", e["pos"], 92.0, 0.0, 0.22)
		return
	e["hp"] -= damage
	e["hurt"] = 0.18
	if CHARACTER_SEQUENCES.has_action(e["kind"], "hurt"):
		e["anim_action"] = "hurt"
		e["anim_time"] = 0.0
		e["anim_duration"] = 0.18
	_spawn_sequence_vfx("crit" if crit else "hit", e["pos"], 136.0 if crit else 82.0, player["facing"], 0.30 if crit else 0.20)
	_add_text(e["pos"] + Vector2(0, -24), str(roundi(damage)), Color(0.96, 0.83, 0.42) if crit else Color(0.93, 0.89, 0.80), 1.45 if crit else 1.0)
	if apply_on_hit and stats.get("slow_chance", 0.0) > 0.0 and randf() < stats["slow_chance"]:
		e["slow"] = 2.2
	if apply_on_hit and stats.get("mud_chance", 0.0) > 0.0 and randf() < stats["mud_chance"]:
		e["slow"] = maxf(e["slow"], 3.0)
		_spawn_ink(e["pos"], 8, Color(0.38, 0.32, 0.23))
	if apply_on_hit and stats.get("steam_chance", 0.0) > 0.0 and randf() < stats["steam_chance"]:
		_apply_area_damage(e["pos"], 120.0, 8.0 + player["damage"] * 0.35, Color(0.55, 0.62, 0.62), index)
	if apply_on_hit and stats.get("poison_fog_chance", 0.0) > 0.0 and randf() < stats["poison_fog_chance"]:
		e["slow"] = maxf(e["slow"], 2.0)
		e["burn"] = maxf(e["burn"], 2.5)
		_apply_area_damage(e["pos"], 96.0, 5.0 + player["damage"] * 0.22, Color(0.30, 0.55, 0.34), index)
	if apply_on_hit and stats.get("mudflame_chance", 0.0) > 0.0 and randf() < stats["mudflame_chance"]:
		e["slow"] = maxf(e["slow"], 2.6)
		_apply_area_damage(e["pos"], 112.0, 7.0 + player["damage"] * 0.28, Color(0.62, 0.32, 0.18), index)
	if apply_on_hit and stats.get("element_burst_chance", 0.0) > 0.0 and randf() < stats["element_burst_chance"]:
		_apply_area_damage(e["pos"], 142.0, 10.0 + player["damage"] * 0.45, ELEMENT_COLORS.values().pick_random(), index)
	if apply_on_hit and player["weapon"].get("id", "") == "shuangren":
		e["slow"] = maxf(e["slow"], 2.5)
	if apply_on_hit and stats.get("burn", 0.0) > 0.0:
		var newly_ignited: bool = e["burn"] <= 0.0
		e["burn"] = 3.0
		e["burn_tick"] = 0.2
		if newly_ignited:
			_spawn_sequence_vfx("fire", e["pos"], 146.0, player["facing"], 0.34, Vector2(1.12, 0.86))
	if player["weapon"].get("id", "") == "yinxue":
		player["hp"] = minf(player["max_hp"], player["hp"] + 1.2)
	if e["hp"] <= 0.0:
		_kill_enemy(index)


func _apply_area_damage(center: Vector2, radius: float, amount: float, ink_color: Color, exclude_index: int = -1) -> void:
	_spawn_ink(center, 12, ink_color)
	for i in range(enemies.size() - 1, -1, -1):
		if i == exclude_index:
			continue
		if i >= enemies.size():
			continue
		if enemies[i]["pos"].distance_to(center) <= radius:
			_damage_enemy(i, amount, false, false)


func _kill_enemy(index: int) -> void:
	var e := enemies[index]
	var e_kind: String = e["kind"]
	var e_pos: Vector2 = e["pos"]
	enemies.remove_at(index)
	player["stones"] += e["stone"]
	enemy_killed.emit(e_kind, e_pos)
	_add_text(e["pos"], "+%d灵石" % e["stone"], Color(0.85, 0.70, 0.36), 1.0)
	_spawn_ink(e["pos"], 28 if e["kind"] == "boss" else 14, Color(0.06, 0.06, 0.06))
	death_actors.append({"kind": e["kind"], "pos": e["pos"], "facing": e.get("facing", 0.0), "ttl": 0.56, "duration": 0.56})
	_spawn_sequence_vfx("death", e["pos"], 218.0 if e["kind"] == "boss" else 132.0, 0.0, 0.52)
	if player["stats"].get("kill_heal", 0.0) > 0.0:
		var heal_scale: float = maxf(0.0, 1.0 + player["stats"].get("recovery_penalty", 0.0))
		player["hp"] = minf(player["max_hp"], player["hp"] + player["max_hp"] * player["stats"]["kill_heal"] * heal_scale)
	if e["kind"] == "elite" or e["kind"] == "boss" or randf() < 0.28:
		_drop_reward(e)
	if enemies.is_empty():
		_clear_room()


func _drop_reward(e: Dictionary) -> void:
	if e["kind"] == "elite" or e["kind"] == "boss":
		var weapon: Dictionary = _roll_weapon(weapons.slice(1).pick_random())
		drops.append({"type": "weapon", "item": weapon, "pos": e["pos"]})
		_show_message("发现武器：%s。靠近按E拾取。" % _weapon_title(weapon), 3.0)
	else:
		var relic: Dictionary = _random_relic()
		drops.append({"type": "relic", "item": relic, "pos": e["pos"]})
		_show_message("发现遗物：%s。靠近按E拾取。" % relic["name"], 2.6)


func _clear_room() -> void:
	rooms[current_room]["cleared"] = true
	telemetry.record("room_clear", {"floor": current_floor, "room": current_room, "type": rooms[current_room]["type"], "hp": player["hp"], "stones": player["stones"]})
	if rooms[current_room]["type"] == "BOSS":
		telemetry.record("boss_clear", {
			"floor": current_floor,
			"boss": "金甲将军",
			"duration_ms": maxi(0, Time.get_ticks_msec() - boss_started_at),
			"hp": player["hp"],
		})
		state = "reward"
		boss_portal = {"pos": ARENA.get_center(), "radius": 44.0, "floor": current_floor}
		_show_message("金甲将军已败。拾取战利品后，靠近中央漩涡门按E结算。", 5.0)
		return

	state = "reward"
	if drops.is_empty():
		drops.append({"type": "relic", "item": _random_relic(), "pos": player["pos"] + Vector2(80, 0)})
	_show_message("房间已清理。拾取奖励后按E进入下一个相邻房间。", 3.0)
	combat_feedback_module.clear_all()
	slash = {}


func _complete_boss_floor() -> void:
	if boss_portal.is_empty():
		return
	var cleared_floor: int = int(boss_portal.get("floor", current_floor))
	boss_portal = {}
	player["karma"] += 30 * current_floor
	current_floor += 1
	floor_changed.emit(current_floor)
	if current_floor > 5:
		# 通关结算：灵石按 5:1 转业力（§15.6）
		var karma_from_stones: int = player["stones"] / 5
		player["karma"] += karma_from_stones
		player["stones"] = player["stones"] % 5
		state = "victory"
		_show_run_result("victory")
		_show_message("通关！业力 %d（灵石转化 %d），Seed %d。按R重开。" % [player["karma"], karma_from_stones, run_seed], 999.0)
		return
	# HP 回复阀门（§15.4）：max(当前HP, 30% max_hp) + 18% max_hp
	player["hp"] = minf(player["max_hp"], maxf(player["hp"], player["max_hp"] * 0.3) + player["max_hp"] * 0.18)
	# 死局保护（§15.5）：HP 低于 15% 时补到 15%
	if player["hp"] < player["max_hp"] * 0.15:
		player["hp"] = player["max_hp"] * 0.15
		telemetry.record("death_safety_net", {"floor": current_floor, "hp": player["hp"]})
	state = "floor_clear"
	_show_settlement(cleared_floor)
	_show_message("第%d层结算：HP部分回复，遗物保留。按E进入第%d层。" % [cleared_floor, current_floor], 999.0)


func _roll_weapon(base_weapon: Dictionary) -> Dictionary:
	var weapon := base_weapon.duplicate(true)
	var options: Array = WEAPON_VARIANTS.get(weapon["id"], [])
	if not options.is_empty():
		weapon["variant"] = options.pick_random().duplicate(true)
	return weapon


func _weapon_title(weapon: Dictionary) -> String:
	var variant: Dictionary = weapon.get("variant", {})
	if variant.is_empty():
		return weapon.get("name", "无")
	return "%s·%s" % [weapon["name"], variant["name"]]


func _weapon_desc(weapon: Dictionary) -> String:
	var text := "基础：%s" % weapon.get("desc", "")
	var variant: Dictionary = weapon.get("variant", {})
	if not variant.is_empty():
		text += "\n副技能：%s\n%s" % [variant["name"], variant["desc"]]
	return text


func _damage_player(amount: float) -> void:
	if player["invuln"] > 0.0 or player["hurt"] > 0.0 or state != "combat":
		return
	var reduction := minf(0.70, player["stats"].get("reduction", 0.0) + player["stats"].get("all", 0.0))
	if player["guard"] > 0.0:
		reduction = minf(0.82, reduction + 0.35)
	var damage := maxf(1.0, amount * (1.0 - reduction))
	player["hp"] -= damage
	player["hurt"] = 0.3
	player["invuln"] = 0.3
	player_damaged.emit(damage, player["hp"])
	_add_text(player["pos"] + Vector2(0, -30), "-%d" % roundi(damage), Color(0.85, 0.36, 0.30), 1.2)
	_shake(5.0, 0.16)
	_spawn_ink(player["pos"], 10, Color(0.62, 0.18, 0.16))
	_set_player_animation("hurt", 0.30)
	_spawn_sequence_vfx("hit", player["pos"], 96.0, 0.0, 0.22)
	if player["hp"] <= 0.0:
		player["hp"] = 0.0
		state = "dead"
		_set_player_animation("dead", 0.64)
		telemetry.record("death", {"floor": current_floor, "room": current_room, "hp": 0, "source": "enemy"})
		_show_run_result("death")
		_show_message("身陨墨渊。业力 %d，灵石 %d。按R重开。" % [player["karma"], player["stones"]], 999.0)


func _interact() -> void:
	if state == "floor_clear":
		_continue_next_floor()
		return

	if _try_read_lore_stele():
		return

	for i in range(drops.size() - 1, -1, -1):
		var drop := drops[i]
		if drop["pos"].distance_to(player["pos"]) < 54.0:
			if drop["type"] == "weapon":
				_open_weapon_choice(i)
				return
			elif player["inventory"].size() < 8:
				player["inventory"].append(drop["item"])
				telemetry.record("relic_get", {"floor": current_floor, "id": drop["item"]["id"], "name": drop["item"]["name"], "source": "drop"})
				_spawn_sequence_vfx("relic_get", player["pos"], 214.0, 0.0, 0.64)
				_show_message("获得遗物 %s。Tab 打开五行盘放入槽位。" % drop["item"]["name"], 3.0)
			else:
				_show_message("背包已满。打开五行盘调整后再拾取。", 2.0)
				return
			drops.remove_at(i)
			_refresh_disk_ui()
			_evaluate_build()
			return

	if not boss_portal.is_empty():
		var portal_pos: Vector2 = boss_portal["pos"]
		if portal_pos.distance_to(player["pos"]) <= boss_portal["radius"] + player["radius"] + 14.0:
			_complete_boss_floor()
			return
		_show_message("中央漩涡门已开启，靠近后按E结算。", 1.5)
		return

	if state == "shop":
		rooms[current_room]["cleared"] = true
		_try_move_room()
	else:
		_try_move_room()


func _try_read_lore_stele() -> bool:
	if rooms.is_empty() or rooms[current_room]["type"] != "START":
		return false
	if player["pos"].distance_to(LORE_STELE_POS) > 58.0:
		return false
	var key := "%d_%d" % [current_floor, current_room]
	var text: String = LORE_TEXTS[(current_floor - 1) % LORE_TEXTS.size()]
	player["lore_seen"][key] = true
	telemetry.record("lore_read", {"floor": current_floor, "room": current_room})
	_show_message(text, 5.0)
	return true


func _show_settlement(cleared_floor: int) -> void:
	if settlement_panel == null:
		return
	var pattern_text := "暂无"
	if not player["patterns"].is_empty():
		pattern_text = " / ".join(player["patterns"].slice(0, 3))
	var combo_text := "暂无"
	if not player["combos"].is_empty():
		combo_text = " / ".join(player["combos"].slice(0, 3))
	# 下层预览信息
	var next_floor_theme := _floor_theme(current_floor)
	var hp_pct: float = player["hp"] / player["max_hp"] * 100.0
	var safety_note := ""
	if hp_pct < 15.0:
		safety_note = "\n[color=yellow]⚠ 气血虚弱，已触发死局保护补至15%[/color]"
	elif hp_pct < 30.0:
		safety_note = "\n[color=yellow]⚠ 气血偏低，下层谨慎行事[/color]"
	var inv_count: int = player["inventory"].size()
	var disk_count := 0
	for item in player["disk"]:
		if item != null:
			disk_count += 1
	settlement_label.text = "[b]第%d层秘境已破[/b]\n\n生命：%d/%d (%.0f%%)%s\n灵石：%d\n业力：%d\n当前武器：%s\n五行格局：%s\n标签组合：%s\n\n[color=88_cc_bb]── 下层预览 ──[/color]\n第%d层·%s\n敌人 HP +%.0f%% / 伤害 +%.0f%% / 灵石 +%.0f%%\n遗物 %d 件（背包 %d + 五行盘 %d）将保留\n武器与五行格局将保留" % [
		cleared_floor,
		ceil(player["hp"]),
		int(player["max_hp"]),
		hp_pct,
		safety_note,
		player["stones"],
		player["karma"],
		_weapon_title(player["weapon"]),
		pattern_text,
		combo_text,
		current_floor,
		next_floor_theme,
		(current_floor - 1) * 28.0,
		(current_floor - 1) * 15.0,
		(current_floor - 1) * 20.0,
		inv_count + disk_count,
		inv_count,
		disk_count,
	]
	settlement_panel.visible = true


func _continue_next_floor() -> void:
	if state != "floor_clear":
		return
	if settlement_panel != null:
		settlement_panel.visible = false
	# 祭坛 buff 跨层清零（§15.3）
	player["stats"].erase("altar_buff")
	_generate_map()
	# 死局保护（§15.5）：进下层前再检查一次
	if player["hp"] < player["max_hp"] * 0.15:
		player["hp"] = player["max_hp"] * 0.15
	# 进入下一层 START 房
	current_room = 0
	rooms[0]["visited"] = true
	rooms[0]["cleared"] = true
	player["pos"] = ARENA.get_center()
	state = "prep"
	_show_message("第%d层·%s：敌人数值上升，保命优先。" % [current_floor, _floor_theme(current_floor)], 3.0)


## 返回层数对应的区域主题名称（§4.4）
func _floor_theme(floor: int) -> String:
	var themes := ["墨渊初境", "锈铁长廊", "碧落回廊", "赤焰熔窟", "归墟深渊"]
	var idx := clampi(floor - 1, 0, themes.size() - 1)
	return themes[idx]


func _show_run_result(outcome: String) -> void:
	if run_result_panel == null:
		return
	var cleared_rooms := 0
	for room in rooms:
		if room["type"] != "empty" and room["cleared"]:
			cleared_rooms += 1
	var pattern_text := "暂无"
	if not player["patterns"].is_empty():
		pattern_text = " / ".join(player["patterns"].slice(0, 3))
	var combo_text := "暂无"
	if not player["combos"].is_empty():
		combo_text = " / ".join(player["combos"].slice(0, 3))
	var title := "通关结算" if outcome == "victory" else "死亡结算"
	var result_line := "墨渊已破" if outcome == "victory" else "身陨墨渊"
	# 通关时灵石转业力（§15.6），死亡不转
	var karma_note := ""
	if outcome == "victory":
		var karma_from_stones: int = player["stones"] / 5
		if karma_from_stones > 0:
			karma_note = "\n灵石 %d → 业力 +%d（5:1 转化）" % [player["stones"], karma_from_stones]
	var deepest_theme := _floor_theme(mini(current_floor, 5))
	run_result_title.text = title
	run_result_label.text = "[b]%s[/b]\n\nSeed：%d\n最深探索：第%d层·%s\n清理房间：%d\n业力：%d\n灵石：%d%s\n当前武器：%s\n五行格局：%s\n标签组合：%s\n\n按 R 或点击按钮重新开始。" % [
		result_line,
		run_seed,
		mini(current_floor, 5),
		deepest_theme,
		cleared_rooms,
		player["karma"],
		player["stones"],
		karma_note,
		_weapon_title(player["weapon"]),
		pattern_text,
		combo_text,
	]
	telemetry.record("run_end", {"outcome": outcome, "floor": current_floor, "rooms_cleared": cleared_rooms, "karma": player["karma"], "stones": player["stones"]})
	run_result_panel.visible = true


func _open_weapon_choice(drop_index: int) -> void:
	if drop_index < 0 or drop_index >= drops.size():
		return
	pending_weapon_drop = drop_index
	var new_weapon: Dictionary = drops[drop_index]["item"]
	var old_weapon: Dictionary = player["weapon"]
	weapon_choice_label.text = "[b]当前[/b] %s · %s\n%s\n\n[b]新武器[/b] [color=#d9b35d]%s · %s[/color]\n%s" % [
		_weapon_title(old_weapon),
		old_weapon.get("type", ""),
		_weapon_desc(old_weapon),
		_weapon_title(new_weapon),
		new_weapon["type"],
		_weapon_desc(new_weapon),
	]
	weapon_choice_panel.visible = true
	_show_message("发现新武器，请选择替换或保留。", 2.0)


func _accept_pending_weapon() -> void:
	if pending_weapon_drop < 0 or pending_weapon_drop >= drops.size():
		weapon_choice_panel.visible = false
		pending_weapon_drop = -1
		return
	var drop := drops[pending_weapon_drop]
	player["weapon"] = drop["item"]
	telemetry.record("weapon_get", {"floor": current_floor, "id": drop["item"]["id"], "name": drop["item"]["name"], "variant": drop["item"].get("variant", {}).get("id", ""), "source": "choice"})
	_spawn_sequence_vfx("weapon_get", player["pos"], 224.0, 0.0, 0.62)
	_show_message("装备 %s。右键使用副技能。" % _weapon_title(drop["item"]), 2.5)
	drops.remove_at(pending_weapon_drop)
	pending_weapon_drop = -1
	weapon_choice_panel.visible = false


func _decline_pending_weapon() -> void:
	if pending_weapon_drop >= 0 and pending_weapon_drop < drops.size():
		var drop := drops[pending_weapon_drop]
		_show_message("保留当前武器，放弃 %s。" % _weapon_title(drop["item"]), 2.0)
		drops.remove_at(pending_weapon_drop)
	pending_weapon_drop = -1
	weapon_choice_panel.visible = false


func _try_move_room() -> void:
	if state == "prep":
		state = "explore"
	var room := rooms[current_room]
	if not room["cleared"] and room["type"] != "START" and room["type"] != "SHOP":
		_show_message("房门被墨锁封住，清完敌人才可离开。", 1.4)
		return

	var options := _visible_exit_links(current_room)
	if options.is_empty():
		for i in rooms.size():
			if rooms[i]["type"] != "empty" and not rooms[i]["cleared"]:
				_show_message("墨径改道，送你前往尚未清理的节点。", 1.6)
				_enter_room(i)
				return
		_show_message("本层已无可探索房间。", 1.8)
		return

	var chosen := _nearest_exit_room()
	if chosen < 0:
		_show_message("靠近亮起的房门后按E进入。", 1.4)
		return
	_enter_room(chosen)


func _available_exit_links(room_index: int) -> Array[int]:
	var result: Array[int] = []
	if room_index < 0 or room_index >= rooms.size():
		return result
	for idx in rooms[room_index]["links"]:
		if rooms[idx]["type"] != "empty" and not rooms[idx]["cleared"]:
			result.append(idx)
	return result


func _visible_exit_links(room_index: int) -> Array[int]:
	var result: Array[int] = _available_exit_links(room_index)
	if result.is_empty() or state in ["shop", "explore", "prep", "reward", "floor_clear"]:
		for idx in rooms[room_index]["links"]:
			if rooms[idx]["type"] != "empty" and not result.has(idx):
				result.append(idx)
	return result


func _nearest_exit_room() -> int:
	var player_pos: Vector2 = player["pos"]
	var best_room := -1
	var best_distance := INF
	for idx in _visible_exit_links(current_room):
		var rect := _exit_rect_for_link(current_room, idx).grow(DOOR_REACH * 0.5)
		var center := rect.get_center()
		var distance := player_pos.distance_to(center)
		if rect.has_point(player_pos) and distance < best_distance:
			best_distance = distance
			best_room = idx
	return best_room


func _exit_rect_for_link(from_idx: int, to_idx: int) -> Rect2:
	var from_room := rooms[from_idx]
	var to_room := rooms[to_idx]
	var dx: int = clampi(to_room["x"] - from_room["x"], -1, 1)
	var dy: int = clampi(to_room["y"] - from_room["y"], -1, 1)
	if dx > 0 and dy < 0:
		return Rect2(ARENA.end.x - 72.0, ARENA.position.y, 72.0, 34.0)
	if dx > 0 and dy > 0:
		return Rect2(ARENA.end.x - 72.0, ARENA.end.y - 34.0, 72.0, 34.0)
	if dx < 0 and dy < 0:
		return Rect2(ARENA.position.x, ARENA.position.y, 72.0, 34.0)
	if dx < 0 and dy > 0:
		return Rect2(ARENA.position.x, ARENA.end.y - 34.0, 72.0, 34.0)
	if dx > 0:
		return Rect2(ARENA.end.x - 18.0, ARENA.get_center().y - 46.0, 18.0, 92.0)
	if dx < 0:
		return Rect2(ARENA.position.x, ARENA.get_center().y - 46.0, 18.0, 92.0)
	if dy > 0:
		return Rect2(ARENA.get_center().x - 54.0, ARENA.end.y - 18.0, 108.0, 18.0)
	return Rect2(ARENA.get_center().x - 54.0, ARENA.position.y, 108.0, 18.0)


func _shop_buy(slot: int) -> void:
	if state != "shop":
		return
	_buy_shop_item(slot - 1)


func _generate_shop_stock() -> Array[Dictionary]:
	var stock: Array[Dictionary] = []
	for i in 3:
		var relic := _random_relic()
		stock.append({"type": "relic", "item": relic, "price": _relic_buy_price(relic), "sold": false})
	stock.append({"type": "weapon", "item": _roll_weapon(weapons.slice(1).pick_random()), "price": WEAPON_BUY_PRICE, "sold": false})
	return stock


func _refresh_shop_ui() -> void:
	if shop_goods_box == null:
		return
	for child in shop_goods_box.get_children():
		child.queue_free()
	for child in shop_sell_grid.get_children():
		child.queue_free()
	for i in shop_stock.size():
		var idx: int = i
		var entry: Dictionary = shop_stock[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(684, 50)
		button.disabled = entry.get("sold", false)
		button.text = _shop_entry_text(entry)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if entry["type"] == "relic":
			_style_relic_button(button, entry["item"])
		button.pressed.connect(func() -> void: _buy_shop_item(idx))
		shop_goods_box.add_child(button)
	for i in player["inventory"].size():
		var idx: int = i
		var item: Dictionary = player["inventory"][i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(162, 46)
		button.text = "%s\n卖 %d" % [item["name"], _relic_sell_price(item)]
		_style_relic_button(button, item)
		button.mouse_entered.connect(func() -> void: _show_shop_detail(item))
		button.pressed.connect(func() -> void: _sell_inventory_item(idx))
		shop_sell_grid.add_child(button)
	shop_detail_label.text = "[color=#c2baaa]灵石 %d。商品会保留在本卦摊，刷新可更换货品。[/color]" % player["stones"]


func _shop_entry_text(entry: Dictionary) -> String:
	if entry.get("sold", false):
		return "已售出"
	var item: Dictionary = entry["item"]
	if entry["type"] == "weapon":
		return "%s  %d灵石\n%s" % [_weapon_title(item), entry["price"], _weapon_desc(item).replace("\n", "  ")]
	return "%s [%s·%s]  %d灵石\n%s" % [item["name"], item["rarity"], ELEMENT_NAMES[item["element"]], entry["price"], item["desc"]]


func _buy_shop_item(index: int) -> void:
	if state != "shop" or index < 0 or index >= shop_stock.size():
		return
	var entry: Dictionary = shop_stock[index]
	if entry.get("sold", false):
		return
	if player["stones"] < entry["price"]:
		_show_message("灵石不足。", 1.2)
		return
	var item: Dictionary = entry["item"]
	if entry["type"] == "relic":
		if player["inventory"].size() >= 8:
			_show_message("背包已满，先出售或整理遗物。", 1.6)
			return
		player["stones"] -= entry["price"]
		player["inventory"].append(item)
		entry["sold"] = true
		telemetry.record("relic_get", {"floor": current_floor, "id": item["id"], "name": item["name"], "source": "shop"})
		_spawn_sequence_vfx("relic_get", player["pos"], 214.0, 0.0, 0.64)
		_show_message("买入遗物：%s" % item["name"], 1.8)
	elif entry["type"] == "weapon":
		player["stones"] -= entry["price"]
		player["weapon"] = item
		entry["sold"] = true
		telemetry.record("weapon_get", {"floor": current_floor, "id": item["id"], "name": item["name"], "variant": item.get("variant", {}).get("id", ""), "source": "shop"})
		_spawn_sequence_vfx("weapon_get", player["pos"], 224.0, 0.0, 0.62)
		_show_message("换得武器：%s" % _weapon_title(item), 1.8)
	rooms[current_room]["shop_stock"] = shop_stock
	_refresh_disk_ui()
	_refresh_shop_ui()


func _sell_inventory_item(index: int) -> void:
	if state != "shop" or index < 0 or index >= player["inventory"].size():
		return
	var item: Dictionary = player["inventory"][index]
	var price := _relic_sell_price(item)
	player["inventory"].remove_at(index)
	player["stones"] += price
	telemetry.record("relic_sell", {"floor": current_floor, "id": item["id"], "name": item["name"], "price": price})
	_show_message("出售遗物：%s +%d灵石" % [item["name"], price], 1.6)
	_refresh_disk_ui()
	_refresh_shop_ui()


func _refresh_shop_paid() -> void:
	if state != "shop":
		return
	if player["stones"] < SHOP_REFRESH_PRICE:
		_show_message("灵石不足，无法刷新。", 1.2)
		return
	player["stones"] -= SHOP_REFRESH_PRICE
	shop_stock = _generate_shop_stock()
	rooms[current_room]["shop_stock"] = shop_stock
	telemetry.record("shop_refresh", {"floor": current_floor, "room": current_room})
	_show_message("卦签重排，货品已刷新。", 1.4)
	_refresh_shop_ui()


func _show_shop_detail(item: Dictionary) -> void:
	if shop_detail_label == null:
		return
	var tag_bits: Array[String] = []
	for tag in item["tags"]:
		tag_bits.append("[bgcolor=%s][color=#111111] %s [/color][/bgcolor]" % [_color_hex(_tag_color(tag)), tag])
	shop_detail_label.text = "[color=%s]■[/color] [b]%s[/b]  [color=%s]%s行[/color]\n%s\n%s" % [
		_color_hex(_rarity_color(item["rarity"])),
		item["name"],
		_color_hex(_element_color(item["element"])),
		ELEMENT_NAMES[item["element"]],
		" ".join(tag_bits),
		item["desc"],
	]


func _relic_buy_price(item: Dictionary) -> int:
	return int(RELIC_BUY_PRICES.get(item["rarity"], 30))


func _relic_sell_price(item: Dictionary) -> int:
	return int(RELIC_SELL_PRICES.get(item["rarity"], 12))


func _random_relic() -> Dictionary:
	var roll := randf()
	var target := "白"
	if roll > 0.95:
		target = "金"
	elif roll > 0.78:
		target = "紫"
	elif roll > 0.45:
		target = "蓝"
	var pool: Array[Dictionary] = []
	for relic in relics:
		if relic["rarity"] == target:
			pool.append(relic)
	return pool.pick_random()


func _evaluate_build() -> void:
	var active: Array = []
	for item in player["disk"]:
		if item != null:
			active.append(item)

	var result: Dictionary = FIVE_ELEMENT_RULES.evaluate(active)
	var stats: Dictionary = result["stats"]
	var patterns: Array[String] = []
	var combos: Array[String] = []
	for name in result["patterns"]:
		patterns.append(name)
	for name in result["combos"]:
		combos.append(name)

	for name in patterns:
		if not discovered.has(name):
			discovered[name] = true
			telemetry.record("pattern_activated", {"floor": current_floor, "name": name})
			var pattern_vfx := "pattern_high" if active.size() >= 4 else ("pattern_mid" if active.size() == 3 else "pattern_low")
			_spawn_sequence_vfx(pattern_vfx, player["pos"], 258.0 if active.size() >= 4 else 218.0, 0.0, 0.72)
			_show_message("发现五行格局：%s" % name, 2.6)
			pattern_discovered.emit(name)
	for name in combos:
		if not discovered.has(name):
			discovered[name] = true
			telemetry.record("tag_combo_activated", {"floor": current_floor, "name": name})
			_show_message("发现标签组合：%s" % name, 2.6)
			combo_discovered.emit(name)

	player["stats"] = stats
	player["patterns"] = patterns
	player["combos"] = combos
	player["element_counts"] = result["counts"].duplicate(true)
	player["max_hp"] = 100.0 + stats["max_hp"]
	player["speed"] = player["base_speed"] * maxf(0.45, 1.0 + stats["speed"] + stats["all"] + stats.get("self_slow", 0.0))
	player["damage"] = 10.0 * (1.0 + stats["all"])
	player["hp"] = minf(player["hp"], player["max_hp"])
	disk_changed.emit(player["disk"])
	_refresh_disk_ui()


func _toggle_disk(show: bool) -> void:
	disk_panel.visible = show
	if shop_panel != null:
		shop_panel.visible = state == "shop" and not show
	if show:
		_refresh_disk_ui()
	elif state == "shop":
		_refresh_shop_ui()


func _refresh_disk_ui() -> void:
	if disk_box == null:
		return
	for child in disk_box.get_children():
		child.queue_free()
	for child in inventory_grid.get_children():
		child.queue_free()
	for child in effect_grid.get_children():
		child.queue_free()

	for i in player["disk"].size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(54, 54)
		var relic = player["disk"][i]
		button.text = _item_button_text(relic) if relic != null else "槽位\n%d" % (i + 1)
		_style_relic_button(button, relic, false, drag_target_index == i)
		if relic != null:
			button.mouse_entered.connect(func() -> void: _show_relic_detail(relic))
			button.focus_entered.connect(func() -> void: _show_relic_detail(relic))
			button.gui_input.connect(func(event) -> void: _disk_drag_input(event, i, relic))
		else:
			button.gui_input.connect(func(event) -> void: _disk_slot_drag_input(event, i))
		button.pressed.connect(func() -> void: _disk_slot_pressed(i))
		disk_box.add_child(button)

	for i in player["inventory"].size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(68, 48)
		button.text = _item_button_text(player["inventory"][i])
		_style_relic_button(button, player["inventory"][i], i == selected_inventory_index)
		button.mouse_entered.connect(func() -> void: _show_relic_detail(player["inventory"][i]))
		button.focus_entered.connect(func() -> void: _show_relic_detail(player["inventory"][i]))
		button.gui_input.connect(func(event) -> void: _inventory_drag_input(event, i))
		button.pressed.connect(func() -> void: _inventory_pressed(i))
		inventory_grid.add_child(button)

	for name in player["patterns"]:
		_add_effect_button(name, PATTERN_DESCS.get(name, "该五行格局已激活，详细效果待数据表补全。"), _effect_color("pattern"))
	for name in player["combos"]:
		_add_effect_button(name, TAG_COMBO_DESCS.get(name, "该标签组合已激活，详细效果待数据表补全。"), _effect_color("combo"))

	var pattern_text := " / ".join(player["patterns"]) if not player["patterns"].is_empty() else "暂无格局"
	var combo_text := " / ".join(player["combos"]) if not player["combos"].is_empty() else "暂无标签组合"
	if hovered_relic == null and not player["inventory"].is_empty():
		_show_relic_detail(player["inventory"][0])
	elif hovered_relic == null:
		_show_relic_detail(null)
	build_label.text = "格局：%s\n组合：%s" % [pattern_text, combo_text]


func _item_button_text(item) -> String:
	if item == null:
		return ""
	return "%s\n%s" % [_short_relic_name(item["name"]), ELEMENT_NAMES[item["element"]]]


func _short_relic_name(name: String) -> String:
	return name if name.length() <= 3 else name.substr(0, 3)


func _add_effect_button(name: String, desc: String, color: Color) -> void:
	var button := Button.new()
	button.text = name
	button.custom_minimum_size = Vector2(94, 26)
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.25)
	style.border_color = color.lightened(0.20)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = color
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color(0.06, 0.055, 0.045))
	button.mouse_entered.connect(func() -> void: _show_effect_detail(name, desc, color))
	button.focus_entered.connect(func() -> void: _show_effect_detail(name, desc, color))
	effect_grid.add_child(button)


func _show_effect_detail(name: String, desc: String, color: Color) -> void:
	hovered_relic = null
	if relic_detail_label == null:
		return
	relic_detail_label.text = "[color=%s]■[/color] [b]%s[/b]\n%s" % [_color_hex(color), name, desc]


func _effect_color(kind: String) -> Color:
	if kind == "pattern":
		return Color(0.85, 0.70, 0.36)
	return Color(0.45, 0.74, 0.95)


func _style_relic_button(button: Button, item, selected: bool = false, is_drop_target: bool = false) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.072, 0.066, 0.96)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	if item != null:
		style.border_color = _rarity_color(item["rarity"])
	else:
		style.border_color = Color(0.91, 0.87, 0.79, 0.18)
	if selected:
		style.bg_color = Color(0.19, 0.14, 0.06, 0.98)
		style.border_color = Color(0.95, 0.72, 0.28)
		style.set_border_width_all(3)
	if is_drop_target:
		style.bg_color = Color(0.06, 0.19, 0.12, 0.98)
		style.border_color = Color(0.44, 0.75, 0.53)
		style.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.14, 0.135, 0.12, 0.95)
	hover.border_color = hover.border_color.lightened(0.25)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color(0.91, 0.87, 0.79))


func _show_relic_detail(item) -> void:
	hovered_relic = item
	if relic_detail_label == null:
		return
	if item == null:
		relic_detail_label.text = "[color=#999999]暂无遗物。[/color]"
		return
	var tag_bits: Array[String] = []
	for tag in item["tags"]:
		tag_bits.append("[bgcolor=%s][color=#111111] %s [/color][/bgcolor]" % [_color_hex(_tag_color(tag)), tag])
	relic_detail_label.text = "[color=%s]■[/color] [b]%s[/b]  [color=%s]%s行[/color]\n%s\n%s" % [
		_color_hex(_rarity_color(item["rarity"])),
		item["name"],
		_color_hex(_element_color(item["element"])),
		ELEMENT_NAMES[item["element"]],
		" ".join(tag_bits),
		item["desc"],
	]


func _element_dot(element: String) -> String:
	return "●"


func _rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, Color(0.82, 0.82, 0.78))


func _element_color(element: String) -> Color:
	return ELEMENT_COLORS.get(element, Color(0.85, 0.81, 0.73))


func _tag_color(tag: String) -> Color:
	return TAG_COLORS.get(tag, Color(0.78, 0.74, 0.66))


func _color_hex(color: Color) -> String:
	return "#%02x%02x%02x" % [roundi(color.r * 255.0), roundi(color.g * 255.0), roundi(color.b * 255.0)]


func _disk_slot_pressed(index: int) -> void:
	if selected_inventory_index >= 0:
		if selected_inventory_index >= player["inventory"].size():
			selected_inventory_index = -1
			_refresh_disk_ui()
			return
		var incoming = player["inventory"][selected_inventory_index]
		var outgoing = player["disk"][index]
		player["disk"][index] = incoming
		if outgoing == null:
			player["inventory"].remove_at(selected_inventory_index)
		else:
			player["inventory"][selected_inventory_index] = outgoing
		selected_inventory_index = -1
		_show_message("五行盘已替换：%s" % incoming["name"], 1.4)
		_evaluate_build()
		return
	var item = player["disk"][index]
	if item == null:
		return
	if player["inventory"].size() >= 8:
		_show_message("背包已满，无法取出。", 1.4)
		return
	player["inventory"].append(item)
	player["disk"][index] = null
	selected_inventory_index = -1
	_evaluate_build()


func _inventory_pressed(index: int) -> void:
	if index < 0 or index >= player["inventory"].size():
		return
	if selected_inventory_index == index:
		selected_inventory_index = -1
		_refresh_disk_ui()
		return
	var slot := -1
	for i in player["disk"].size():
		if player["disk"][i] == null:
			slot = i
			break
	if slot < 0:
		selected_inventory_index = index
		_show_message("五行盘已满：已选中 %s，点击盘内槽位进行替换。" % player["inventory"][index]["name"], 2.0)
		_refresh_disk_ui()
		return
	player["disk"][slot] = player["inventory"][index]
	player["inventory"].remove_at(index)
	selected_inventory_index = -1
	_evaluate_build()


func _inventory_drag_input(event, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and drag_relic == null:
			drag_relic = player["inventory"][index]
			drag_source = "inventory"
			drag_source_index = index
			selected_inventory_index = -1
			_show_drag_sprite()
		elif not event.pressed and drag_relic != null:
			_drop_drag()


func _disk_drag_input(event, index: int, relic) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and drag_relic == null:
			drag_relic = relic
			drag_source = "disk"
			drag_source_index = index
			player["disk"][index] = null
			_evaluate_build()
			_show_drag_sprite()
		elif not event.pressed and drag_relic != null:
			_drop_drag()


func _disk_slot_drag_input(event, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and drag_relic != null:
			_drop_drag()


func _show_drag_sprite() -> void:
	if drag_sprite != null:
		drag_sprite.queue_free()
	drag_sprite = Label.new()
	drag_sprite.text = _item_button_text(drag_relic)
	drag_sprite.add_theme_font_size_override("font_size", 16)
	drag_sprite.add_theme_color_override("font_color", _rarity_color(drag_relic["rarity"]))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.072, 0.066, 0.92)
	style.set_border_width_all(2)
	style.border_color = _rarity_color(drag_relic["rarity"])
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	drag_sprite.add_theme_stylebox_override("normal", style)
	drag_sprite.custom_minimum_size = Vector2(72, 54)
	drag_sprite.visible = true
	ui_layer.add_child(drag_sprite)
	drag_sprite.position = get_global_mouse_position() - Vector2(36, 27)


func _drop_drag() -> void:
	var mouse_pos := get_global_mouse_position()
	drag_target_index = -1
	for i in player["disk"].size():
		var button = disk_box.get_child(i) if i < disk_box.get_child_count() else null
		if button != null:
			var rect := Rect2(button.get_global_position(), button.custom_minimum_size)
			if rect.has_point(mouse_pos):
				drag_target_index = i
				break
	if drag_sprite != null:
		drag_sprite.queue_free()
		drag_sprite = null
	if drag_target_index >= 0:
		_apply_drag_to_slot(drag_target_index)
	else:
		if drag_source == "disk":
			player["disk"][drag_source_index] = drag_relic
			_evaluate_build()
			_show_message("放回原位：%s" % drag_relic["name"], 1.2)
		elif drag_source == "inventory":
			_show_message("取消拖拽：%s" % drag_relic["name"], 1.2)
	drag_relic = null
	drag_source = ""
	drag_source_index = -1
	drag_target_index = -1
	_refresh_disk_ui()


func _apply_drag_to_slot(target_index: int) -> void:
	var target_relic = player["disk"][target_index]
	if drag_source == "inventory":
		if target_relic == null:
			player["disk"][target_index] = drag_relic
			player["inventory"].remove_at(drag_source_index)
			_show_message("放入五行盘：%s" % drag_relic["name"], 1.4)
		else:
			player["disk"][target_index] = drag_relic
			player["inventory"][drag_source_index] = target_relic
			_show_message("替换：%s → %s" % [target_relic["name"], drag_relic["name"]], 1.4)
	elif drag_source == "disk":
		if target_relic == null:
			player["disk"][target_index] = drag_relic
			_show_message("移动到槽位 %d：%s" % [target_index + 1, drag_relic["name"]], 1.4)
		else:
			player["disk"][drag_source_index] = target_relic
			player["disk"][target_index] = drag_relic
			_show_message("交换：%s ↔ %s" % [drag_relic["name"], target_relic["name"]], 1.4)
	_evaluate_build()


func _update_drag_preview() -> void:
	var mouse_pos := get_global_mouse_position()
	var new_target := -1
	for i in player["disk"].size():
		var button = disk_box.get_child(i) if i < disk_box.get_child_count() else null
		if button != null:
			var rect := Rect2(button.get_global_position(), button.custom_minimum_size)
			if rect.has_point(mouse_pos):
				new_target = i
				break
	if new_target != drag_target_index:
		drag_target_index = new_target
		_refresh_disk_ui()
	if drag_target_index >= 0:
		var preview_disk: Array = player["disk"].duplicate()
		preview_disk[drag_target_index] = drag_relic
		var preview_relics := []
		for r in preview_disk:
			if r != null:
				preview_relics.append(r)
		if preview_relics.size() > 0:
			var RULES = preload("res://scripts/FiveElementRules.gd")
			var rules := RULES.new()
			var result := rules.evaluate(preview_relics)
			var pattern_text := " / ".join(result["patterns"]) if not result["patterns"].is_empty() else "暂无格局"
			var combo_text := " / ".join(result["combos"]) if not result["combos"].is_empty() else "暂无标签组合"
			build_label.text = "预览：\n格局：%s\n组合：%s" % [pattern_text, combo_text]
		else:
			build_label.text = "预览：\n格局：暂无\n组合：暂无"
	else:
		var pattern_text := " / ".join(player["patterns"]) if not player["patterns"].is_empty() else "暂无格局"
		var combo_text := " / ".join(player["combos"]) if not player["combos"].is_empty() else "暂无标签组合"
		build_label.text = "格局：%s\n组合：%s" % [pattern_text, combo_text]


func _update_effects(delta: float) -> void:
	if not slash.is_empty():
		slash["ttl"] -= delta
		if slash["ttl"] <= 0.0:
			slash = {}
	for i in range(particles.size() - 1, -1, -1):
		var p := particles[i]
		p["pos"] += p["vel"] * delta
		p["life"] -= delta
		p["vel"] *= 0.94
		if p["life"] <= 0.0:
			particles.remove_at(i)
	for i in range(impact_effects.size() - 1, -1, -1):
		impact_effects[i]["ttl"] -= delta
		if impact_effects[i]["ttl"] <= 0.0 or impact_effects[i].get("duration", 0.0) <= 0.0:
			impact_effects.remove_at(i)
	for i in range(death_actors.size() - 1, -1, -1):
		death_actors[i]["ttl"] -= delta
		if death_actors[i]["ttl"] <= 0.0:
			death_actors.remove_at(i)
	for i in range(float_texts.size() - 1, -1, -1):
		var t := float_texts[i]
		t["pos"].y -= 34.0 * delta
		t["life"] -= delta
		if t["life"] <= 0.0:
			float_texts.remove_at(i)


func _hit_stop(seconds: float) -> void:
	hit_stop_time = maxf(hit_stop_time, seconds)
	hit_flash_duration = maxf(hit_flash_duration, clampf(seconds * 1.35, 0.045, 0.12))
	hit_flash_time = hit_flash_duration


func _shake(amount: float, seconds: float) -> void:
	shake_amount = maxf(shake_amount, amount)
	shake_time = maxf(shake_time, seconds)
	shake_duration = maxf(shake_duration, seconds)
	shake_elapsed = 0.0


func _update_combat_feedback(delta: float) -> void:
	if shake_time > 0.0:
		shake_time = maxf(0.0, shake_time - delta)
		shake_elapsed += delta
		if shake_time <= 0.0:
			shake_amount = 0.0
			shake_duration = 0.0
	if hit_flash_time > 0.0:
		hit_flash_time = maxf(0.0, hit_flash_time - delta)
	if hit_stop_time > 0.0:
		hit_stop_time = maxf(0.0, hit_stop_time - delta)


func _spawn_ink(pos: Vector2, count: int, color: Color) -> void:
	for i in count:
		var angle := randf_range(0.0, TAU)
		var speed := randf_range(40.0, 210.0)
		particles.append({"pos": pos, "vel": Vector2.RIGHT.rotated(angle) * speed, "life": randf_range(0.35, 0.9), "size": randf_range(2.0, 8.0), "color": color})


func _spawn_sequence_vfx(kind: String, pos: Vector2, size: float, angle: float = 0.0, duration: float = 0.30, stretch: Vector2 = Vector2.ONE) -> void:
	if not VFX_SEQUENCES.has_sequence(kind):
		return
	var safe_duration := maxf(duration, 0.05)
	var slot: String = RESETTABLE_VFX_SLOTS.get(kind, "")
	if not slot.is_empty():
		_clear_vfx_slot(slot)
	var effect := {"kind": kind, "pos": pos, "size": size, "angle": angle, "ttl": safe_duration, "duration": safe_duration, "stretch": stretch}
	if not slot.is_empty():
		effect["slot"] = slot
	impact_effects.append(effect)


func _clear_vfx_slot(slot: String) -> void:
	for i in range(impact_effects.size() - 1, -1, -1):
		if impact_effects[i].get("slot", "") == slot:
			impact_effects.remove_at(i)


func _add_text(pos: Vector2, text: String, color: Color, scale: float) -> void:
	float_texts.append({"pos": pos, "text": text, "color": color, "scale": scale, "life": 0.9})


func _show_message(text: String, seconds: float) -> void:
	message_label.text = text
	message_label.visible = true
	message_time = seconds


func _draw() -> void:
	var offset := Vector2.ZERO
	if shake_amount > 0.0 and shake_duration > 0.0:
		var decay := pow(clampf(shake_time / shake_duration, 0.0, 1.0), 1.7)
		offset = Vector2(
			sin(shake_elapsed * 37.0),
			cos(shake_elapsed * 31.0 + 0.65)
		) * shake_amount * decay
	draw_camera_offset = offset
	draw_set_transform(offset)
	_draw_background()
	_draw_arena()
	_draw_lore_stele()
	_draw_boss_arena_features()
	_draw_doors()
	_draw_boss_portal()
	_draw_drops()
	_draw_projectiles()
	_draw_actors()
	_draw_slash()
	_draw_impact_effects()
	_draw_debug_anchor_targets()
	_draw_particles()
	_draw_float_texts()
	draw_set_transform(Vector2.ZERO)
	draw_camera_offset = Vector2.ZERO
	_draw_combat_flash()
	if state != "menu":
		_draw_ui_masks()
		_draw_hud()
		_draw_map()
		_draw_right_info()


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.052, 0.054, 0.055), true)
	draw_rect(LEFT_RAIL, Color(0.025, 0.026, 0.026, 0.96), true)
	draw_rect(RIGHT_RAIL, Color(0.025, 0.026, 0.026, 0.96), true)
	draw_rect(TOP_SAFE, Color(0.04, 0.042, 0.045, 0.58), true)
	draw_rect(BOTTOM_SAFE, Color(0.04, 0.042, 0.045, 0.58), true)
	for x in range(-80, int(VIEW_SIZE.x) + 80, 80):
		draw_line(Vector2(x, 0), Vector2(x - 80, VIEW_SIZE.y), Color(0.91, 0.87, 0.79, 0.055), 1.0)
	draw_line(Vector2(LEFT_RAIL.end.x, 0), Vector2(LEFT_RAIL.end.x, VIEW_SIZE.y), Color(0.82, 0.64, 0.28, 0.28), 2.0)
	draw_line(Vector2(RIGHT_RAIL.position.x, 0), Vector2(RIGHT_RAIL.position.x, VIEW_SIZE.y), Color(0.82, 0.64, 0.28, 0.28), 2.0)


func _draw_ui_masks() -> void:
	draw_rect(LEFT_RAIL, Color(0.025, 0.026, 0.026, 0.98), true)
	draw_rect(RIGHT_RAIL, Color(0.025, 0.026, 0.026, 0.98), true)
	draw_rect(TOP_SAFE, Color(0.04, 0.042, 0.045, 0.96), true)
	draw_rect(BOTTOM_SAFE, Color(0.04, 0.042, 0.045, 0.96), true)
	draw_line(Vector2(LEFT_RAIL.end.x, 0), Vector2(LEFT_RAIL.end.x, VIEW_SIZE.y), Color(0.82, 0.64, 0.28, 0.30), 2.0)
	draw_line(Vector2(RIGHT_RAIL.position.x, 0), Vector2(RIGHT_RAIL.position.x, VIEW_SIZE.y), Color(0.82, 0.64, 0.28, 0.30), 2.0)


func _draw_combat_flash() -> void:
	if hit_flash_time <= 0.0 or hit_flash_duration <= 0.0:
		return
	var life := clampf(hit_flash_time / hit_flash_duration, 0.0, 1.0)
	var pulse := sin(life * PI)
	draw_rect(ARENA, Color(1.0, 0.90, 0.62, pulse * 0.085), true)
	draw_rect(ARENA, Color(1.0, 0.95, 0.78, pulse * 0.22), false, 2.0)


func _draw_arena() -> void:
	draw_rect(ARENA, Color(0.91, 0.87, 0.79, 0.035), true)
	draw_rect(ARENA, Color(0.82, 0.64, 0.28, 0.22), false, 2.0)
	draw_line(ARENA.position + Vector2(18, 10), Vector2(ARENA.end.x - 18, ARENA.position.y + 10), Color(0.91, 0.87, 0.79, 0.08), 1.0)


func _draw_lore_stele() -> void:
	if rooms.is_empty() or rooms[current_room]["type"] != "START":
		return
	var pos := LORE_STELE_POS
	draw_rect(Rect2(pos - Vector2(18, 28), Vector2(36, 56)), Color(0.20, 0.19, 0.17, 0.92), true)
	draw_rect(Rect2(pos - Vector2(18, 28), Vector2(36, 56)), Color(0.85, 0.70, 0.36, 0.35), false, 2.0)
	draw_line(pos + Vector2(-8, -10), pos + Vector2(8, -10), Color(0.85, 0.70, 0.36, 0.65), 2.0)
	draw_line(pos + Vector2(-8, 2), pos + Vector2(8, 2), Color(0.85, 0.70, 0.36, 0.50), 2.0)
	if player["pos"].distance_to(pos) <= 70.0:
		draw_string(font, pos + Vector2(-42, 48), "E 读残卷", HORIZONTAL_ALIGNMENT_CENTER, 84, 13, Color(0.91, 0.87, 0.79))


func _draw_boss_arena_features() -> void:
	for hazard in boss_hazards:
		var alpha := clampf(hazard["ttl"] / 3.5, 0.12, 0.34)
		draw_circle(hazard["pos"], hazard["radius"], Color(0.24, 0.55, 0.31, alpha))
		draw_arc(hazard["pos"], hazard["radius"], 0.0, TAU, 28, Color(0.44, 0.75, 0.53, 0.55), 2.0)
	for pillar in boss_pillars:
		var pos: Vector2 = pillar["pos"]
		var points := PackedVector2Array([pos + Vector2(0, -30), pos + Vector2(24, 0), pos + Vector2(0, 30), pos + Vector2(-24, 0)])
		draw_colored_polygon(points, Color(0.31, 0.30, 0.27))
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(0.72, 0.68, 0.58), 3.0)

	for boss in enemies:
		if boss.get("kind", "") != "boss" or boss.get("boss_state", "") != "telegraph":
			continue
		var progress := 1.0 - clampf(boss["boss_timer"] / maxf(0.01, boss["telegraph_total"]), 0.0, 1.0)
		var warning := Color(0.91, 0.34, 0.25, 0.18 + progress * 0.30)
		if boss["boss_action"] == "cleave":
			draw_colored_polygon(_sector_points(boss["pos"], boss["facing"], 200.0, PI * 0.5), warning)
		elif boss["boss_action"] == "sweep":
			draw_circle(boss["pos"], 150.0, warning)
			draw_arc(boss["pos"], 150.0, 0.0, TAU, 48, Color(0.96, 0.58, 0.35, 0.75), 3.0 + progress * 3.0)
		elif boss["boss_action"] == "charge":
			var end: Vector2 = boss["pos"] + Vector2.RIGHT.rotated(boss["facing"]) * 400.0
			draw_line(boss["pos"], end, Color(0.91, 0.34, 0.25, 0.72), 18.0)


func _sector_points(center: Vector2, facing: float, radius: float, arc: float) -> PackedVector2Array:
	var points := PackedVector2Array([center])
	for i in 13:
		var angle := facing - arc * 0.5 + arc * float(i) / 12.0
		points.append(center + Vector2.RIGHT.rotated(angle) * radius)
	return points


func _draw_doors() -> void:
	if state == "menu" or rooms.is_empty():
		return
	var exits := _visible_exit_links(current_room)
	var locked: bool = state == "combat" and not rooms[current_room]["cleared"]
	for idx in exits:
		var rect := _exit_rect_for_link(current_room, idx)
		var is_near := rect.grow(DOOR_REACH * 0.5).has_point(player["pos"])
		var room_type: String = rooms[idx]["type"]
		if locked:
			draw_rect(rect, Color(0.12, 0.08, 0.07, 0.88), true)
			draw_rect(rect, Color(0.55, 0.24, 0.20, 0.72), false, 2.0)
			draw_line(rect.position + Vector2(3, 3), rect.end - Vector2(3, 3), Color(0.72, 0.32, 0.26), 2.0)
			draw_line(Vector2(rect.end.x - 3, rect.position.y + 3), Vector2(rect.position.x + 3, rect.end.y - 3), Color(0.72, 0.32, 0.26), 2.0)
			continue
		var base := Color(0.85, 0.70, 0.36, 0.22)
		if room_type == "BOSS":
			base = Color(0.85, 0.32, 0.28, 0.30)
		elif room_type == "SHOP":
			base = Color(0.36, 0.61, 0.78, 0.28)
		elif room_type == "ELITE":
			base = Color(0.85, 0.70, 0.36, 0.34)
		if is_near:
			base.a = 0.58
		draw_rect(rect, base, true)
		draw_rect(rect, Color(0.91, 0.87, 0.79, 0.28 if not is_near else 0.72), false, 2.0)
		draw_circle(rect.get_center(), 8.0, Color(0.05, 0.045, 0.04, 0.70))
		_draw_room_icon(rect.get_center(), room_type, is_near)


func _draw_boss_portal() -> void:
	if boss_portal.is_empty():
		return
	var pos: Vector2 = boss_portal["pos"]
	var radius: float = boss_portal["radius"]
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 220.0)
	draw_circle(pos, radius, Color(0.36, 0.61, 0.78, 0.16 + pulse * 0.08))
	draw_arc(pos, radius, 0.0, TAU, 48, Color(0.85, 0.70, 0.36, 0.75), 4.0)
	draw_arc(pos, radius * 0.62, PI * pulse, TAU + PI * pulse, 48, Color(0.91, 0.87, 0.79, 0.55), 3.0)
	draw_circle(pos, 12.0 + pulse * 4.0, Color(0.05, 0.045, 0.04, 0.92))
	draw_string(font, pos + Vector2(-48, 64), "漩涡门 · E结算", HORIZONTAL_ALIGNMENT_CENTER, 96, 14, Color(0.91, 0.87, 0.79))


func _draw_actors() -> void:
	var actors: Array[Dictionary] = []
	for enemy in enemies:
		actors.append({"type": "enemy", "data": enemy, "y": enemy["pos"].y})
	for death_actor in death_actors:
		actors.append({"type": "death", "data": death_actor, "y": death_actor["pos"].y})
	if state != "menu":
		actors.append({"type": "player", "y": player["pos"].y})
	actors.sort_custom(_actor_draw_order)
	for actor in actors:
		if actor["type"] == "player":
			_draw_player()
		elif actor["type"] == "death":
			_draw_dead_actor(actor["data"])
		else:
			_draw_enemy(actor["data"])


func _actor_draw_order(a: Dictionary, b: Dictionary) -> bool:
	return float(a["y"]) < float(b["y"])


func _draw_player() -> void:
	var pos: Vector2 = player["pos"]
	var alpha := 0.55 if player["invuln"] > 0.0 else 1.0
	var action: String = player.get("anim_action", "idle")
	if not CHARACTER_SEQUENCES.has_action("player", action):
		action = "idle"
	var sample: Dictionary
	if action == "idle" or action == "run":
		sample = _character_sample_at("player", action, 0.0, 0.0, player.get("loop_clock", 0.0))
	else:
		sample = _character_sample("player", action, player.get("anim_time", 0.0), player.get("anim_duration", 0.0))
	_draw_actor_shadow(pos, player["radius"], alpha)
	_draw_actor_sprite("player", pos, player["facing"], Color(1.0, 0.94, 0.78, alpha) if player["hurt"] > 0.0 else Color(1.0, 1.0, 1.0, alpha), action, sample)


func _draw_enemy(e: Dictionary) -> void:
	var pos: Vector2 = e["pos"]
	var radius: float = e["radius"]
	_draw_actor_shadow(pos, radius, 1.0)
	draw_arc(pos, radius + 4.0, 0.0, TAU, 28, Color(ELEMENT_COLORS[e["element"]], 0.64), 2.0)
	if e["slow"] > 0.0:
		draw_arc(pos, radius + 8.0, 0.15, PI * 1.55, 22, Color(0.38, 0.72, 0.92, 0.76), 2.0)
	if e["burn"] > 0.0:
		draw_arc(pos, radius + 11.0, PI, TAU * 0.92, 18, Color(0.95, 0.38, 0.20, 0.78), 2.0)
	var action := _enemy_animation_action(e)
	var sample := _enemy_animation_sample(e, action)
	var tint := Color(1.0, 0.78, 0.50) if e["hurt"] > 0.0 else Color.WHITE
	_draw_actor_sprite(e["kind"], pos, e.get("facing", 0.0), tint, action, sample)
	if e["ai"] == "shielder":
		draw_arc(pos, radius + 7.0, -1.1, 1.1, 16, Color(0.94, 0.90, 0.82), 4.0)
	if e["ai"] == "boss" and e.get("boss_state", "") == "stunned":
		draw_arc(pos, radius + 14.0, -PI, 0.0, 16, Color(0.95, 0.74, 0.30), 4.0)
	var visual_size: Vector2 = CHARACTER_SEQUENCES.draw_size(e["kind"])
	var bar_width := 94.0 if e["kind"] == "boss" else (66.0 if e["kind"] == "elite" else 52.0)
	var bar_pos := pos + Vector2(-bar_width * 0.5, -visual_size.y * 0.47 - 10.0)
	_draw_bar(bar_pos, Vector2(bar_width, 5.0), e["hp"] / e["max_hp"], Color(0.77, 0.35, 0.29))


func _draw_dead_actor(actor: Dictionary) -> void:
	var kind: String = actor["kind"]
	var ttl: float = actor["ttl"]
	var duration: float = actor["duration"]
	var sample := _sequence_sample(ttl, duration, CHARACTER_SEQUENCES.frame_count(kind))
	var progress := clampf(1.0 - ttl / maxf(duration, 0.001), 0.0, 1.0)
	var alpha := clampf((1.0 - progress) * 4.0, 0.0, 1.0) if progress > 0.75 else 1.0
	_draw_actor_sprite(kind, actor["pos"], actor.get("facing", 0.0), Color(1.0, 1.0, 1.0, alpha), "dead", sample)


func _draw_actor_shadow(pos: Vector2, radius: float, alpha: float) -> void:
	draw_set_transform(pos + draw_camera_offset + Vector2(0.0, radius * 0.62), 0.0, Vector2(1.45, 0.38))
	draw_circle(Vector2.ZERO, radius, Color(0.01, 0.01, 0.01, 0.42 * alpha))
	draw_set_transform(draw_camera_offset)


func _draw_actor_sprite(kind: String, pos: Vector2, facing: float, tint: Color, action: String, sample: Dictionary) -> void:
	var flip_x := -1.0 if cos(facing) < -0.05 else 1.0
	var phase: float = sample["phase"]
	var visible_frame: int = sample["next_frame"] if phase >= 0.60 else sample["frame"]
	var draw_size: Vector2 = CHARACTER_SEQUENCES.frame_draw_size(kind, action, visible_frame)
	var anchor := CHARACTER_SEQUENCES.anchor(kind, action, visible_frame)
	var breathing := sin(animation_clock * TAU * (1.8 if action == "idle" else 3.2))
	var scale_y := 1.0 + breathing * (0.008 if action == "idle" else 0.004)
	var dest := Rect2(-anchor * draw_size, draw_size)
	draw_set_transform(pos + draw_camera_offset, 0.0, Vector2(flip_x, scale_y))
	draw_texture_rect_region(CHARACTER_SEQUENCES.texture(kind), dest, CHARACTER_SEQUENCES.region(kind, action, visible_frame), tint, false, true)
	draw_set_transform(draw_camera_offset)


func _character_frame(kind: String, action: String, ttl: float, duration: float) -> int:
	var sample := _character_sample(kind, action, ttl, duration)
	return sample["next_frame"] if sample["phase"] >= 0.60 else sample["frame"]


func _character_sample(kind: String, action: String, ttl: float, duration: float) -> Dictionary:
	return _character_sample_at(kind, action, ttl, duration, animation_clock)


func _character_sample_at(kind: String, action: String, ttl: float, duration: float, clock: float) -> Dictionary:
	var frame_count := CHARACTER_SEQUENCES.frame_count(kind)
	if action == "idle" or action == "run":
		var fps := 12.0 if action == "run" else 8.0
		var frame_position := clock * fps
		var frame := int(floor(frame_position)) % frame_count
		return {"frame": frame, "next_frame": (frame + 1) % frame_count, "phase": frame_position - floor(frame_position), "progress": 0.0}
	if action == "dead" and ttl <= 0.0:
		return {"frame": frame_count - 1, "next_frame": frame_count - 1, "phase": 0.0, "progress": 1.0}
	return _sequence_sample(ttl, duration, frame_count)


func _enemy_animation_action(enemy: Dictionary) -> String:
	var kind: String = enemy["kind"]
	var timed_action: String = enemy.get("anim_action", "idle")
	if enemy.get("hurt", 0.0) > 0.0 and CHARACTER_SEQUENCES.has_action(kind, "hurt"):
		return "hurt"
	if enemy.get("anim_time", 0.0) > 0.0 and CHARACTER_SEQUENCES.has_action(kind, timed_action):
		return timed_action
	return "run" if enemy.get("moving", false) else "idle"


func _enemy_animation_frame(enemy: Dictionary, action: String) -> int:
	var sample := _enemy_animation_sample(enemy, action)
	return sample["next_frame"] if sample["phase"] >= 0.60 else sample["frame"]


func _enemy_animation_sample(enemy: Dictionary, action: String) -> Dictionary:
	if action == "idle" or action == "run":
		return _character_sample_at(enemy["kind"], action, 0.0, 0.0, enemy.get("loop_clock", 0.0))
	if action == "hurt":
		return _sequence_sample(enemy.get("hurt", 0.0), 0.18, CHARACTER_SEQUENCES.frame_count(enemy["kind"]))
	return _character_sample(enemy["kind"], action, enemy.get("anim_time", 0.0), enemy.get("anim_duration", 0.0))


func _sequence_frame(ttl: float, duration: float, frame_count: int = 8) -> int:
	return _sequence_sample(ttl, duration, frame_count)["frame"]


func _sequence_sample(ttl: float, duration: float, frame_count: int = 8) -> Dictionary:
	var progress := clampf(1.0 - ttl / maxf(duration, 0.001), 0.0, 1.0)
	var frame_position := minf(progress * frame_count, frame_count - 0.0001)
	var frame := clampi(int(floor(frame_position)), 0, frame_count - 1)
	var next_frame := mini(frame + 1, frame_count - 1)
	return {"frame": frame, "next_frame": next_frame, "phase": frame_position - floor(frame_position), "progress": progress}


func _draw_slash() -> void:
	if slash.is_empty():
		return
	var is_heavy: bool = slash["combo"] == 3
	var kind := "combo_%d" % int(slash["combo"])
	var sample := _sequence_sample(slash["ttl"], slash.get("duration", 0.20), VFX_SEQUENCES.frame_count(kind))
	var size: float = slash["range"] * (2.20 if is_heavy else 1.92)
	var draw_size := Vector2(size, size * (0.84 if is_heavy else 0.68))
	var forward := Vector2.RIGHT.rotated(slash["angle"])
	var center: Vector2 = slash["pos"] + forward * slash["range"] * (0.50 if is_heavy else 0.56)
	draw_set_transform(center + draw_camera_offset, slash["angle"], Vector2.ONE)
	_draw_vfx_sequence(kind, draw_size, sample)
	draw_set_transform(draw_camera_offset)


func _draw_impact_effects() -> void:
	for effect in impact_effects:
		var kind: String = effect["kind"]
		if not VFX_SEQUENCES.has_sequence(kind):
			continue
		var sample := _sequence_sample(effect["ttl"], effect["duration"], VFX_SEQUENCES.frame_count(kind))
		var size: float = effect["size"]
		var stretch: Vector2 = effect.get("stretch", Vector2.ONE)
		var draw_size := Vector2(size, size) * stretch
		draw_set_transform(effect["pos"] + draw_camera_offset, effect["angle"], Vector2.ONE)
		_draw_vfx_sequence(kind, draw_size, sample)
		draw_set_transform(draw_camera_offset)


func _draw_debug_anchor_targets() -> void:
	if not OS.is_debug_build() or debug_anchor_targets.is_empty():
		return
	for pos in debug_anchor_targets:
		draw_circle(pos, 4.0, Color(0.24, 0.92, 0.92, 0.95))
		draw_line(pos + Vector2(-10.0, 0.0), pos + Vector2(10.0, 0.0), Color(0.24, 0.92, 0.92, 0.82), 1.0)
		draw_line(pos + Vector2(0.0, -10.0), pos + Vector2(0.0, 10.0), Color(0.24, 0.92, 0.92, 0.82), 1.0)


func _draw_projectiles() -> void:
	for p in projectiles:
		var color := ELEMENT_COLORS["wood"] if p.get("kind", "") == "vine" else Color(0.86, 0.86, 0.84)
		if p.get("owner", "") == "player":
			var sequence_kind: String = p.get("kind", "sword_wave")
			if not VFX_SEQUENCES.has_sequence(sequence_kind):
				sequence_kind = "combo_1"
			var sample := _sequence_sample(p["ttl"], p.get("duration", p["ttl"]), VFX_SEQUENCES.frame_count(sequence_kind))
			var size := 238.0 if sequence_kind == "rainbow_cut" else (196.0 if sequence_kind == "return_blade" else 214.0)
			var draw_size := Vector2(size, size * (0.72 if sequence_kind == "return_blade" else 0.58))
			draw_set_transform(p["pos"] + draw_camera_offset, p["vel"].angle(), Vector2.ONE)
			_draw_vfx_sequence(sequence_kind, draw_size, sample)
			draw_set_transform(draw_camera_offset)
		else:
			draw_circle(p["pos"], p["radius"], color)


func _draw_vfx_sequence(kind: String, draw_size: Vector2, sample: Dictionary, tint: Color = Color.WHITE) -> void:
	var frame: int = sample["frame"]
	var next_frame: int = sample["next_frame"]
	if next_frame == frame:
		draw_texture_rect_region(VFX_SEQUENCES.texture(kind), _vfx_frame_rect(kind, frame, draw_size), VFX_SEQUENCES.region(kind, frame), tint, false, true)
		return
	var blend := smoothstep(0.74, 1.0, float(sample["phase"]))
	var outgoing := tint
	outgoing.a *= 1.0 - blend
	var incoming := tint
	incoming.a *= blend
	if outgoing.a > 0.01:
		draw_texture_rect_region(VFX_SEQUENCES.texture(kind), _vfx_frame_rect(kind, frame, draw_size), VFX_SEQUENCES.region(kind, frame), outgoing, false, true)
	if incoming.a > 0.01:
		draw_texture_rect_region(VFX_SEQUENCES.texture(kind), _vfx_frame_rect(kind, next_frame, draw_size), VFX_SEQUENCES.region(kind, next_frame), incoming, false, true)


func _vfx_frame_rect(kind: String, frame: int, draw_size: Vector2) -> Rect2:
	return Rect2(-VFX_SEQUENCES.anchor(kind, frame) * draw_size, draw_size)


func _draw_drops() -> void:
	for drop in drops:
		var color: Color = Color(0.85, 0.70, 0.36) if drop["type"] == "weapon" else ELEMENT_COLORS[drop["item"]["element"]]
		var pos: Vector2 = drop["pos"]
		var points := PackedVector2Array([pos + Vector2(0, -16), pos + Vector2(16, 0), pos + Vector2(0, 16), pos + Vector2(-16, 0)])
		draw_colored_polygon(points, color)
		var label: String = _weapon_title(drop["item"]) if drop["type"] == "weapon" else drop["item"]["name"]
		draw_string(font, pos + Vector2(-38, 34), label, HORIZONTAL_ALIGNMENT_CENTER, 76, 13, Color(0.91, 0.87, 0.79))


func _draw_particles() -> void:
	for p in particles:
		var color: Color = p["color"]
		color.a = clampf(p["life"] * 1.8, 0.0, 1.0)
		draw_circle(p["pos"], p["size"], color)


func _draw_float_texts() -> void:
	for t in float_texts:
		var color: Color = t["color"]
		color.a = clampf(t["life"], 0.0, 1.0)
		draw_string(font, t["pos"], t["text"], HORIZONTAL_ALIGNMENT_CENTER, 80, int(18 * t["scale"]), color)


func _draw_hud() -> void:
	_draw_ink_panel(Rect2(8, 10, 126, 322), Color(0.82, 0.64, 0.28, 0.34))
	draw_line(Vector2(16, 178), Vector2(126, 178), Color(0.82, 0.64, 0.28, 0.22), 1.0)
	draw_string(font, Vector2(16, 28), "燕无归", HORIZONTAL_ALIGNMENT_LEFT, 112, 18, Color(0.91, 0.87, 0.79))
	_draw_bar(Vector2(16, 44), Vector2(110, 14), player["hp"] / player["max_hp"], Color(0.77, 0.35, 0.29))
	draw_string(font, Vector2(16, 77), "%d/%d HP" % [ceil(player["hp"]), int(player["max_hp"])], HORIZONTAL_ALIGNMENT_LEFT, 112, 13, Color(0.91, 0.87, 0.79))
	draw_string(font, Vector2(16, 110), "灵石 %d" % player["stones"], HORIZONTAL_ALIGNMENT_LEFT, 112, 14, Color(0.85, 0.70, 0.36))
	draw_string(font, Vector2(16, 136), "业力 %d" % player["karma"], HORIZONTAL_ALIGNMENT_LEFT, 112, 14, Color(0.76, 0.73, 0.66))
	draw_string(font, Vector2(16, 180), "武器", HORIZONTAL_ALIGNMENT_LEFT, 112, 13, Color(0.76, 0.73, 0.66))
	draw_string(font, Vector2(16, 204), _weapon_title(player["weapon"]), HORIZONTAL_ALIGNMENT_LEFT, 112, 15, Color(0.91, 0.87, 0.79))
	draw_string(font, Vector2(16, 230), player["weapon"].get("type", ""), HORIZONTAL_ALIGNMENT_LEFT, 112, 13, Color(0.85, 0.70, 0.36))
	draw_string(font, Vector2(16, 256), "副技 %.1fs" % player["subskill_cd"], HORIZONTAL_ALIGNMENT_LEFT, 112, 14, Color(0.85, 0.70, 0.36))
	draw_string(font, Vector2(16, 284), "连击 %d/3" % player["combo"], HORIZONTAL_ALIGNMENT_LEFT, 112, 15, Color(0.91, 0.87, 0.79))
	draw_string(font, Vector2(16, 312), "闪避 %.1fs" % player["dodge_cd"], HORIZONTAL_ALIGNMENT_LEFT, 112, 15, Color(0.91, 0.87, 0.79))
	_draw_ink_panel(Rect2(174, 680, 816, 28), Color(0.82, 0.64, 0.28, 0.24))
	draw_string(font, Vector2(174, 699), "WASD移动 · 左键/J攻击 · 右键副技 · Space闪避 · E交互 · Tab五行盘", HORIZONTAL_ALIGNMENT_CENTER, 816, 13, Color(0.91, 0.87, 0.79))
	_draw_boss_hud()


func _draw_boss_hud() -> void:
	for boss in enemies:
		if boss.get("kind", "") != "boss":
			continue
		var panel_rect := Rect2(ARENA.get_center().x - 227.0, 8.0, 454.0, 62.0)
		var bar_pos := panel_rect.position + Vector2(12.0, 16.0)
		_draw_ink_panel(panel_rect, Color(0.68, 0.23, 0.18, 0.42))
		draw_string(font, panel_rect.position + Vector2(12.0, 9.0), "金甲将军 · 阶段%d · %s" % [boss["phase"], ELEMENT_NAMES[boss["element"]]], HORIZONTAL_ALIGNMENT_LEFT, 430, 15, Color(0.92, 0.86, 0.75))
		_draw_bar(bar_pos, Vector2(430, 12), boss["hp"] / boss["max_hp"], Color(0.76, 0.25, 0.20))
		if boss.get("shield", 0.0) > 0.0:
			_draw_bar(bar_pos + Vector2(0, 16), Vector2(430, 7), boss["shield"] / boss["max_shield"], ELEMENT_COLORS["metal"])
			return
		if boss.get("boss_state", "") == "telegraph":
			var action_name: String = BOSS_ACTION_NAMES.get(boss["boss_action"], boss["boss_action"])
			draw_string(font, bar_pos + Vector2(0, 32), "%s  %.1fs" % [action_name, maxf(0.0, boss["boss_timer"])], HORIZONTAL_ALIGNMENT_CENTER, 430, 15, Color(0.95, 0.63, 0.35))
		elif boss.get("boss_state", "") == "stunned":
			draw_string(font, bar_pos + Vector2(0, 32), "撞柱眩晕  %.1fs" % maxf(0.0, boss["boss_timer"]), HORIZONTAL_ALIGNMENT_CENTER, 430, 15, Color(0.95, 0.78, 0.35))
		return


func _draw_map() -> void:
	var start := Vector2(1036, 40)
	var cell := 32.0
	draw_rect(Rect2(start - Vector2(16, 32), Vector2(248, 184)), Color(0.055, 0.050, 0.044, 0.78), true)
	draw_rect(Rect2(start - Vector2(16, 32), Vector2(248, 184)), Color(0.85, 0.70, 0.36, 0.12), false, 2.0)
	draw_string(font, start + Vector2(0, -15), "秘境图卷", HORIZONTAL_ALIGNMENT_LEFT, 120, 14, Color(0.76, 0.73, 0.66))
	for i in rooms.size():
		var room := rooms[i]
		if room["type"] == "empty":
			continue
		var from_pos := start + Vector2(room["x"], room["y"]) * cell + Vector2(10, 10)
		for idx in room["links"]:
			if idx <= i or rooms[idx]["type"] == "empty":
				continue
			var to_room := rooms[idx]
			var to_pos := start + Vector2(to_room["x"], to_room["y"]) * cell + Vector2(10, 10)
			var link_color := Color(0.85, 0.70, 0.36, 0.16)
			if room["visited"] or to_room["visited"] or i == current_room or idx == current_room:
				link_color = Color(0.85, 0.70, 0.36, 0.42)
			draw_line(from_pos, to_pos, link_color, 2.0)
	for i in rooms.size():
		var room := rooms[i]
		if room["type"] == "empty":
			continue
		var pos := start + Vector2(room["x"], room["y"]) * cell
		var color := Color(0.91, 0.87, 0.79, 0.13)
		if i == current_room:
			color = Color(0.85, 0.70, 0.36)
		elif room["cleared"]:
			color = Color(0.91, 0.87, 0.79, 0.22)
		elif room["visited"]:
			color = Color(0.91, 0.87, 0.79, 0.55)
		draw_circle(pos + Vector2(10, 10), 11.0 if i == current_room else 9.0, color)
		draw_arc(pos + Vector2(10, 10), 12.0, 0.0, TAU, 24, Color(0.08, 0.07, 0.06, 0.72), 2.0)
		_draw_room_icon(pos + Vector2(10, 10), room["type"], i == current_room)


func _draw_right_info() -> void:
	if disk_panel.visible or (shop_panel != null and shop_panel.visible) or (settlement_panel != null and settlement_panel.visible) or (run_result_panel != null and run_result_panel.visible):
		return
	var x := 1030.0
	var y := 210.0
	var content_width := 228.0
	_draw_ink_panel(Rect2(x - 10.0, y - 18.0, 248.0, 360.0), Color(0.82, 0.64, 0.28, 0.26))
	draw_string(font, Vector2(x, y), "当前房间", HORIZONTAL_ALIGNMENT_LEFT, content_width, 14, Color(0.76, 0.73, 0.66))
	draw_string(font, Vector2(x, y + 28.0), _room_type_name(rooms[current_room]["type"]) if not rooms.is_empty() else "未开始", HORIZONTAL_ALIGNMENT_LEFT, content_width, 20, Color(0.91, 0.87, 0.79))
	draw_string(font, Vector2(x, y + 66.0), "目标", HORIZONTAL_ALIGNMENT_LEFT, content_width, 14, Color(0.76, 0.73, 0.66))
	draw_string(font, Vector2(x, y + 92.0), _room_objective_text(), HORIZONTAL_ALIGNMENT_LEFT, content_width, 14, Color(0.91, 0.87, 0.79))
	draw_string(font, Vector2(x, y + 142.0), "五行格局", HORIZONTAL_ALIGNMENT_LEFT, content_width, 14, Color(0.76, 0.73, 0.66))
	var pattern_text := "未成格局"
	if not player["patterns"].is_empty():
		pattern_text = " / ".join(player["patterns"].slice(0, 2))
	draw_string(font, Vector2(x, y + 168.0), pattern_text, HORIZONTAL_ALIGNMENT_LEFT, content_width, 14, Color(0.91, 0.87, 0.79))
	draw_string(font, Vector2(x, y + 218.0), "标签组合", HORIZONTAL_ALIGNMENT_LEFT, content_width, 14, Color(0.76, 0.73, 0.66))
	var combo_text := "暂无组合"
	if not player["combos"].is_empty():
		combo_text = " / ".join(player["combos"].slice(0, 2))
	draw_string(font, Vector2(x, y + 244.0), combo_text, HORIZONTAL_ALIGNMENT_LEFT, content_width, 14, Color(0.91, 0.87, 0.79))
	_draw_active_tag_chips(Vector2(x, y + 276.0), content_width)
	draw_string(font, Vector2(x, y + 322.0), "Tab 打开五行盘", HORIZONTAL_ALIGNMENT_LEFT, content_width, 14, Color(0.85, 0.70, 0.36))


func _room_objective_text() -> String:
	if state == "combat":
		for enemy in enemies:
			if enemy.get("kind", "") == "boss":
				if enemy.get("shield", 0.0) > 0.0:
					return "破除金盾：火元素伤害×2"
				if enemy.get("boss_state", "") == "telegraph":
					return "%s：观察红色预警" % BOSS_ACTION_NAMES.get(enemy["boss_action"], enemy["boss_action"])
				if enemy.get("boss_state", "") == "stunned":
					return "撞柱眩晕：全力输出"
				return "诱导冲刺撞柱，闪避前摇"
		return "清除敌人：%d" % enemies.size()
	if state == "reward":
		if not boss_portal.is_empty():
			return "拾取战利品，进入漩涡门"
		return "拾取奖励，靠近门按E"
	if state == "shop":
		return "1买遗物 / 2换武器 / E离开"
	if state == "floor_clear":
		return "按E进入下一层"
	if state == "prep" or state == "explore":
		if not rooms.is_empty() and rooms[current_room]["type"] == "START":
			return "读残卷，或靠近门按E"
		return "靠近门按E进入"
	if state == "dead":
		return "按R重开"
	if state == "victory":
		return "通关，按R重开"
	return "探索墨渊"


func _draw_active_tag_chips(start: Vector2, max_width: float) -> void:
	var tags := _active_disk_tags()
	if tags.is_empty():
		draw_string(font, start + Vector2(0, 14), "暂无标签", HORIZONTAL_ALIGNMENT_LEFT, max_width, 13, Color(0.76, 0.73, 0.66))
		return
	var cursor := start
	for tag in tags.slice(0, 6):
		var width := 32.0
		if cursor.x + width > start.x + max_width:
			break
		_draw_tag_chip(Rect2(cursor, Vector2(width, 22.0)), tag)
		cursor.x += width + 6.0


func _draw_tag_chip(rect: Rect2, tag: String) -> void:
	var color := _tag_color(tag)
	draw_rect(rect, color, true)
	draw_rect(rect, Color(0.91, 0.87, 0.79, 0.28), false, 1.0)
	draw_string(font, rect.position + Vector2(0, 15), tag, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13, Color(0.06, 0.055, 0.045))


func _draw_ink_panel(rect: Rect2, accent: Color) -> void:
	draw_rect(rect, Color(0.018, 0.018, 0.017, 0.78), true)
	draw_rect(rect, Color(0.91, 0.87, 0.79, 0.08), false, 1.0)
	draw_line(rect.position + Vector2(0, 1), Vector2(rect.end.x, rect.position.y + 1), accent, 2.0)


func _active_disk_tags() -> Array[String]:
	var result: Array[String] = []
	for relic in player["disk"]:
		if relic == null:
			continue
		for tag in relic["tags"]:
			if not result.has(tag):
				result.append(tag)
	return result


func _draw_room_icon(center: Vector2, room_type: String, active: bool) -> void:
	var ink := Color(0.08, 0.07, 0.06)
	if active:
		ink = Color(0.06, 0.045, 0.02)
	match room_type:
		"START":
			draw_circle(center, 5.5, ink)
			draw_circle(center, 2.5, Color(0.91, 0.87, 0.79, 0.85))
		"MONSTER":
			draw_line(center + Vector2(-5, -5), center + Vector2(5, 5), ink, 2.0)
			draw_line(center + Vector2(5, -5), center + Vector2(-5, 5), ink, 2.0)
		"ELITE":
			var points := PackedVector2Array([center + Vector2(0, -7), center + Vector2(7, 0), center + Vector2(0, 7), center + Vector2(-7, 0)])
			draw_colored_polygon(points, ink)
			draw_circle(center, 2.4, Color(0.91, 0.87, 0.79, 0.85))
		"SHOP":
			draw_rect(Rect2(center + Vector2(-6, -4), Vector2(12, 8)), ink, false, 2.0)
			draw_line(center + Vector2(-4, -5), center + Vector2(4, -5), ink, 2.0)
			draw_circle(center + Vector2(0, 3), 2.0, ink)
		"BOSS":
			draw_circle(center, 6.5, ink)
			draw_rect(Rect2(center + Vector2(-4, -1), Vector2(8, 5)), Color(0.91, 0.87, 0.79, 0.85), true)
			draw_circle(center + Vector2(-2.4, -1), 1.2, ink)
			draw_circle(center + Vector2(2.4, -1), 1.2, ink)
		_:
			draw_circle(center, 4.0, ink)


func _room_short(room_type: String) -> String:
	match room_type:
		"START":
			return "起"
		"MONSTER":
			return "战"
		"ELITE":
			return "精"
		"SHOP":
			return "商"
		"BOSS":
			return "王"
	return "?"


func _room_type_name(room_type: String) -> String:
	match room_type:
		"START":
			return "START房 · 环境叙事"
		"MONSTER":
			return "普通战斗房"
		"ELITE":
			return "精英战斗房"
		"SHOP":
			return "卦摊商店"
		"BOSS":
			return "层Boss房"
	return "未知节点"


func _draw_bar(pos: Vector2, size: Vector2, pct: float, color: Color) -> void:
	draw_rect(Rect2(pos, size), Color(0.0, 0.0, 0.0, 0.42), true)
	draw_rect(Rect2(pos, Vector2(size.x * clampf(pct, 0.0, 1.0), size.y)), color, true)
	draw_rect(Rect2(pos, size), Color(0.91, 0.87, 0.79, 0.35), false, 1.0)
