extends RefCounted

const ELEMENT_NAMES := {
	"metal": "金",
	"wood": "木",
	"water": "水",
	"fire": "火",
	"earth": "土",
}

const BASE_STATS := {
	"damage": 0.0,
	"speed": 0.0,
	"reduction": 0.0,
	"max_hp": 0.0,
	"crit": 0.0,
	"regen": 0.0,
	"range": 0.0,
	"slow_chance": 0.0,
	"burn": 0.0,
	"burn_power": 0.0,
	"all": 0.0,
	"cd": 0.0,
	"kill_heal": 0.0,
	"armor_damage": 0.0,
	"noncrit_damage": 0.0,
	"self_slow": 0.0,
	"dodge_cd_add": 0.0,
	"mud_chance": 0.0,
	"steam_chance": 0.0,
	"poison_fog_chance": 0.0,
	"mudflame_chance": 0.0,
	"armor_pierce": 0.0,
	"recovery_penalty": 0.0,
	"crit_disabled": 0.0,
	"no_regen": 0.0,
	"cycle_element": 0.0,
	"element_burst_chance": 0.0,
	"yuan_pulse": 0.0,
}

const SINGLE_PATTERNS := {
	"metal": {"exact_counts": {"metal": 5}, "name": "锐金之极", "tier": 5, "priority": 72, "stats": {"crit": 0.10}},
	"wood": {"exact_counts": {"wood": 5}, "name": "生生不息", "tier": 5, "priority": 72, "stats": {"max_hp": 15.0, "kill_heal": 0.15, "regen": 0.2}},
	"water": {"exact_counts": {"water": 5}, "name": "渊流无尽", "tier": 5, "priority": 72, "stats": {"cd": 0.15, "slow_chance": 0.20}},
	"fire": {"exact_counts": {"fire": 5}, "name": "焚天烈焰", "tier": 5, "priority": 72, "stats": {"damage": 0.10, "burn": 1.0}},
	"earth": {"exact_counts": {"earth": 5}, "name": "万钧之重", "tier": 5, "priority": 72, "stats": {"reduction": 0.15}},
}

const GEN_PAIRS := [
	{"elements": ["metal", "water"], "name": "金水相生", "tier": 3, "priority": 25, "stats": {"crit": 0.08}},
	{"elements": ["water", "wood"], "name": "水木相生", "tier": 3, "priority": 25, "stats": {"regen": 1.0}},
	{"elements": ["wood", "fire"], "name": "木火相生", "tier": 3, "priority": 25, "stats": {"damage": 0.05, "burn_power": 0.40}},
	{"elements": ["fire", "earth"], "name": "火土相生", "tier": 3, "priority": 25, "stats": {"reduction": 0.08}},
	{"elements": ["earth", "metal"], "name": "土金相生", "tier": 3, "priority": 25, "stats": {"damage": 0.05}},
]

const OPP_PAIRS := [
	{"elements": ["metal", "wood"], "name": "金木交锋", "tier": 3, "priority": 20, "stats": {"armor_damage": 0.30, "crit": 0.04, "reduction": -0.04}},
	{"elements": ["wood", "earth"], "name": "木土相争", "tier": 3, "priority": 20, "stats": {"kill_heal": 0.08, "speed": 0.05}},
	{"elements": ["earth", "water"], "name": "土水交冲", "tier": 3, "priority": 20, "stats": {"mud_chance": 0.18, "self_slow": -0.12, "dodge_cd_add": 0.25}},
	{"elements": ["water", "fire"], "name": "水火不容", "tier": 4, "priority": 20, "stats": {"steam_chance": 0.20, "damage": 0.08, "reduction": -0.05}},
	{"elements": ["fire", "metal"], "name": "火金相克", "tier": 4, "priority": 20, "stats": {"crit": 0.10, "burn": 1.0, "noncrit_damage": -0.12}},
]

const CHAIN_TRIPLES := [
	{"elements": ["metal", "water", "wood"], "name": "金水木·涌泉", "tier": 4, "priority": 40, "stats": {"crit": 0.05, "regen": 0.8, "damage": 0.04}},
	{"elements": ["water", "wood", "fire"], "name": "水木火·燎原", "tier": 4, "priority": 40, "stats": {"regen": 0.8, "burn_power": 0.35}},
	{"elements": ["wood", "fire", "earth"], "name": "木火土·熔铸", "tier": 4, "priority": 40, "stats": {"damage": 0.06, "reduction": 0.06, "burn_power": 0.25}},
	{"elements": ["fire", "earth", "metal"], "name": "火土金·锻锋", "tier": 4, "priority": 40, "stats": {"damage": 0.08, "crit": 0.04}},
	{"elements": ["earth", "metal", "water"], "name": "土金水·沉渊", "tier": 4, "priority": 40, "stats": {"reduction": 0.08, "slow_chance": 0.12}},
]

const MIX_TRIPLES := [
	{"elements": ["fire", "water", "wood"], "name": "火水木·蒸腾", "tier": 4, "priority": 46, "stats": {"poison_fog_chance": 0.18, "burn_power": -0.20, "slow_chance": 0.06}},
	{"elements": ["earth", "water", "fire"], "name": "土水火·泥焰", "tier": 4, "priority": 46, "stats": {"mudflame_chance": 0.20, "speed": -0.04}},
	{"elements": ["metal", "wood", "fire"], "name": "金木火·淬刃", "tier": 4, "priority": 46, "stats": {"armor_pierce": 0.20, "crit": 0.05, "burn_power": 0.18}},
	{"elements": ["water", "earth", "metal"], "name": "水土金·沉锻", "tier": 5, "priority": 64, "stats": {"reduction": 0.10, "recovery_penalty": -0.25}},
	{"elements": ["wood", "fire", "earth"], "name": "木火土·灰烬", "tier": 4, "priority": 47, "stats": {"kill_heal": 0.04, "damage": 0.06, "regen": -0.3}},
]

const QUAD_PATTERNS := [
	{"elements": ["metal", "wood", "water", "fire"], "exact_total": 4, "name": "四象轮转", "tier": 5, "priority": 61, "stats": {"cycle_element": 1.0, "all": 0.06}},
	{"elements": ["metal", "wood", "water", "earth"], "exact_total": 4, "name": "四象轮转", "tier": 5, "priority": 61, "stats": {"cycle_element": 1.0, "all": 0.06}},
	{"elements": ["metal", "wood", "fire", "earth"], "exact_total": 4, "name": "四象轮转", "tier": 5, "priority": 61, "stats": {"cycle_element": 1.0, "all": 0.06}},
	{"elements": ["metal", "water", "fire", "earth"], "exact_total": 4, "name": "四象轮转", "tier": 5, "priority": 60, "stats": {"cycle_element": 1.0, "all": 0.06}},
	{"elements": ["wood", "water", "fire", "earth"], "exact_total": 4, "name": "四象轮转", "tier": 5, "priority": 61, "stats": {"cycle_element": 1.0, "all": 0.06}},
	{"elements": ["metal", "water", "fire", "earth"], "exact_total": 4, "name": "金水火土·破界", "tier": 5, "priority": 62, "stats": {"damage": 0.10, "crit": 0.06, "regen": -0.5, "no_regen": 1.0, "element_burst_chance": 0.10}},
	{"elements": ["wood", "fire", "earth", "water"], "exact_total": 4, "name": "木火土水·四象归元", "tier": 5, "priority": 62, "stats": {"regen": 1.0, "reduction": 0.08, "burn_power": 0.20, "crit_disabled": 1.0}},
]

const ALL_FIVE := {"exact_counts": {"metal": 1, "wood": 1, "water": 1, "fire": 1, "earth": 1}, "name": "五行圆满", "tier": 5, "priority": 100, "stats": {"crit": 0.04, "regen": 0.4, "cd": 0.04, "damage": 0.04, "reduction": 0.04, "slow_chance": 0.05, "burn_power": 0.10, "yuan_pulse": 1.0}}

const TAG_COMBOS := [
	# 基础 5 种（P0 验证级）
	{"tags": ["锐", "裂"], "name": "破甲墨锋", "stats": {"crit": 0.08}},
	{"tags": ["焚", "裂"], "name": "爆燃裂帛", "stats": {"burn_power": 0.60}},
	{"tags": ["吸", "魂"], "name": "摄魂回元", "stats": {"kill_heal": 0.06}},
	{"tags": ["冻", "蚀"], "name": "寒蚀入骨", "stats": {"slow_chance": 0.12}},
	{"tags": ["厚", "障"], "name": "山门不动", "stats": {"reduction": 0.08}},
	# 暴击 / 攻击流（6 种）
	{"tags": ["锐", "蓄"], "name": "聚力穿心", "stats": {"damage": 0.08, "crit": 0.05}},
	{"tags": ["锐", "震"], "name": "雷霆一击", "stats": {"crit": 0.06, "damage": 0.05}},
	{"tags": ["锐", "迅"], "name": "疾风剑", "stats": {"speed": 0.08, "crit": 0.05}},
	{"tags": ["锐", "影"], "name": "背刺之影", "stats": {"crit": 0.10, "damage": 0.04}},
	{"tags": ["锐", "弹"], "name": "穿透弹射", "stats": {"range": 0.20, "crit": 0.05}},
	{"tags": ["焚", "锐"], "name": "焰刃", "stats": {"burn_power": 0.30, "crit": 0.05}},
	# 灼烧 / 持续伤流（5 种）
	{"tags": ["焚", "蓄"], "name": "炽焰重击", "stats": {"burn": 1.0, "damage": 0.05}},
	{"tags": ["焚", "蚀"], "name": "腐蚀烈焰", "stats": {"burn_power": 0.35, "damage": 0.04}},
	{"tags": ["焚", "震"], "name": "烈焰爆破", "stats": {"burn_power": 0.25, "range": 0.15}},
	{"tags": ["焚", "迅"], "name": "疾风烈焰", "stats": {"speed": 0.08, "burn_power": 0.20}},
	{"tags": ["裂", "震"], "name": "碎地冲击", "stats": {"damage": 0.06, "range": 0.15}},
	# 防御 / 生存流（6 种）
	{"tags": ["厚", "镜"], "name": "玄甲反震", "stats": {"reduction": 0.06, "damage": 0.04}},
	{"tags": ["障", "镜"], "name": "反射结界", "stats": {"reduction": 0.05, "range": 0.10}},
	{"tags": ["厚", "迅"], "name": "铁壁疾行", "stats": {"reduction": 0.05, "speed": 0.06}},
	{"tags": ["吸", "厚"], "name": "血甲", "stats": {"kill_heal": 0.04, "reduction": 0.05}},
	{"tags": ["魂", "厚"], "name": "亡魂护甲", "stats": {"kill_heal": 0.05, "reduction": 0.06}},
	{"tags": ["障", "冻"], "name": "冰封屏障", "stats": {"reduction": 0.06, "slow_chance": 0.08}},
	# 控制 / 限制流（5 种）
	{"tags": ["冻", "缚"], "name": "冰封锁链", "stats": {"slow_chance": 0.15, "reduction": 0.04}},
	{"tags": ["蚀", "缚"], "name": "腐蚀锁链", "stats": {"slow_chance": 0.12, "damage": 0.04}},
	{"tags": ["聚", "散"], "name": "潮汐引力", "stats": {"slow_chance": 0.10, "speed": 0.05}},
	{"tags": ["障", "散"], "name": "排斥护盾", "stats": {"reduction": 0.05, "speed": 0.05}},
	{"tags": ["厚", "缚"], "name": "铁锁横江", "stats": {"reduction": 0.08, "damage": 0.03}},
	# 机动 / 闪避流（4 种）
	{"tags": ["迅", "影"], "name": "鬼步", "stats": {"speed": 0.10, "dodge_cd_add": -0.20}},
	{"tags": ["弹", "迅"], "name": "疾速弹射", "stats": {"speed": 0.06, "range": 0.15}},
	{"tags": ["吸", "迅"], "name": "疾风吸血", "stats": {"speed": 0.08, "kill_heal": 0.03}},
	{"tags": ["魂", "迅"], "name": "亡魂疾行", "stats": {"speed": 0.10, "kill_heal": 0.04}},
	# 召唤 / 特殊流（4 种）
	{"tags": ["召", "厚"], "name": "灵甲护体", "stats": {"reduction": 0.04, "max_hp": 10.0}},
	{"tags": ["召", "障"], "name": "灵盾", "stats": {"reduction": 0.05, "regen": 0.3}},
	{"tags": ["印", "冻"], "name": "冰冻烙印", "stats": {"slow_chance": 0.14, "damage": 0.05}},
	{"tags": ["印", "锐"], "name": "弱点洞悉", "stats": {"crit": 0.08, "damage": 0.06}},
]


static func evaluate(active_relics: Array) -> Dictionary:
	var stats := BASE_STATS.duplicate(true)
	var counts := {"metal": 0, "wood": 0, "water": 0, "fire": 0, "earth": 0}
	var tags: Array[String] = []

	for relic in active_relics:
		for key in relic["stats"].keys():
			stats[key] = stats.get(key, 0.0) + relic["stats"][key]
		var element: String = relic["element"]
		if counts.has(element):
			counts[element] += 1
		if relic["id"] == "five_elements":
			for key in counts.keys():
				counts[key] += 1
		for tag in relic["tags"]:
			tags.append(tag)

	var candidates: Array[Dictionary] = []
	for element in counts.keys():
		if _matches_rule(counts, SINGLE_PATTERNS[element]):
			candidates.append(SINGLE_PATTERNS[element])

	for rule in GEN_PAIRS:
		if _matches_rule(counts, rule):
			candidates.append(rule)

	for rule in OPP_PAIRS:
		if _matches_rule(counts, rule):
			candidates.append(rule)

	for rule in CHAIN_TRIPLES:
		if _matches_rule(counts, rule):
			candidates.append(rule)

	for rule in MIX_TRIPLES:
		if _matches_rule(counts, rule):
			candidates.append(rule)

	for rule in QUAD_PATTERNS:
		if _matches_rule(counts, rule):
			candidates.append(rule)

	if _matches_rule(counts, ALL_FIVE):
		candidates.append(ALL_FIVE)

	var patterns := _select_dominant_patterns(candidates)
	for rule in patterns:
		_apply_rule_stats(stats, rule)

	var combos: Array[String] = []
	for rule in TAG_COMBOS:
		if _has_tags(tags, rule["tags"]):
			_add_rule(combos, stats, rule)

	var pattern_names: Array[String] = []
	for rule in patterns:
		pattern_names.append(rule["name"])

	return {"stats": stats, "patterns": pattern_names, "combos": combos, "counts": counts, "tags": tags}


static func _has_elements(counts: Dictionary, elements: Array) -> bool:
	for element in elements:
		if counts.get(element, 0) <= 0:
			return false
	return true


static func _matches_rule(counts: Dictionary, rule: Dictionary) -> bool:
	if rule.has("exact_total") and _element_total(counts) != int(rule["exact_total"]):
		return false
	if rule.has("exact_counts"):
		return _has_exact_counts(counts, rule["exact_counts"])
	return _has_elements(counts, rule.get("elements", []))


static func _has_exact_counts(counts: Dictionary, exact_counts: Dictionary) -> bool:
	for element in counts.keys():
		if counts[element] != exact_counts.get(element, 0):
			return false
	return true


static func _element_total(counts: Dictionary) -> int:
	var total := 0
	for value in counts.values():
		total += int(value)
	return total


static func _has_tags(tags: Array[String], required: Array) -> bool:
	for tag in required:
		if not tags.has(tag):
			return false
	return true


static func _add_rule(names: Array[String], stats: Dictionary, rule: Dictionary) -> void:
	names.append(rule["name"])
	_apply_rule_stats(stats, rule)


static func _apply_rule_stats(stats: Dictionary, rule: Dictionary) -> void:
	for key in rule["stats"].keys():
		stats[key] = stats.get(key, 0.0) + rule["stats"][key]


static func _select_dominant_patterns(candidates: Array[Dictionary]) -> Array[Dictionary]:
	if candidates.is_empty():
		return []
	candidates.sort_custom(_compare_pattern_rules)
	return [candidates[0]]


static func _compare_pattern_rules(a: Dictionary, b: Dictionary) -> bool:
	var a_exact := 1 if a.has("exact_counts") or a.has("exact_total") else 0
	var b_exact := 1 if b.has("exact_counts") or b.has("exact_total") else 0
	if a_exact != b_exact:
		return a_exact > b_exact
	if a.get("tier", 0) != b.get("tier", 0):
		return a.get("tier", 0) > b.get("tier", 0)
	if _rule_element_size(a) != _rule_element_size(b):
		return _rule_element_size(a) > _rule_element_size(b)
	return a.get("priority", 0) > b.get("priority", 0)


static func _rule_element_size(rule: Dictionary) -> int:
	if rule.has("exact_counts"):
		var size := 0
		for value in rule["exact_counts"].values():
			if int(value) > 0:
				size += 1
		return size
	return rule.get("elements", []).size()
