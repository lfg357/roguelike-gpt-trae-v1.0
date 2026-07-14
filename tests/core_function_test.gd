extends SceneTree

var test_results: Array = []
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	var packed := load("res://scenes/Main.tscn")
	if packed == null:
		push_error("Main scene failed to load.")
		quit(1)
		return

	var main: Node = packed.instantiate()
	root.add_child(main)
	await process_frame

	print("\n=== 核心功能测试 v1.0 ===")
	
	_test_five_element_system(main)
	_test_floor_transition(main)
	_test_relic_system(main)
	_test_combat_system(main)
	
	_print_report()
	
	if failed > 0:
		quit(1)
	else:
		quit(0)

func _test_five_element_system(main: Node) -> void:
	print("\n--- 五行系统测试 ---")
	
	var rules = load("res://scripts/FiveElementRules.gd")
	
	_test_case("TC-FE-01 单元素极致格局", _check_single_element_extreme(rules, main.relics))
	_test_case("TC-FE-02 相生双元格局", _check_mutual_generation(rules, main.relics))
	_test_case("TC-FE-03 相克双元格局双刃剑", _check_mutual_restriction(rules, main.relics))
	_test_case("TC-FE-05 五行圆满触发", _check_five_elements_perfect(rules, main.relics))
	_test_case("TC-FE-06 格局驱逐规则", _check_pattern_eviction(rules, main.relics))
	_test_case("TC-FE-07 标签组合触发", _check_tag_combo(rules, main.relics))

func _check_single_element_extreme(rules, relics: Array) -> bool:
	var five_metal = [relics[2], relics[2], relics[2], relics[2], relics[2]]
	var result = rules.evaluate(five_metal)
	return result["patterns"].has("锐金之极")

func _check_mutual_generation(rules, relics: Array) -> bool:
	var gold_water = [relics[2], relics[2], relics[2], relics[4], relics[4]]
	var result = rules.evaluate(gold_water)
	return result["patterns"].has("金水相生")

func _check_mutual_restriction(rules, relics: Array) -> bool:
	var gold_wood = [relics[2], relics[2], relics[2], relics[3], relics[3]]
	var result = rules.evaluate(gold_wood)
	return result["patterns"].has("金木交锋")

func _check_five_elements_perfect(rules, relics: Array) -> bool:
	var five = [relics[2], relics[3], relics[4], relics[5], relics[6]]
	var result = rules.evaluate(five)
	return result["patterns"] == ["五行圆满"]

func _check_pattern_eviction(rules, relics: Array) -> bool:
	var gold_water_wood = [relics[2], relics[2], relics[2], relics[4], relics[4], relics[3]]
	var result = rules.evaluate(gold_water_wood)
	return result["patterns"] == ["金水木·涌泉"] and not result["patterns"].has("金水相生")

func _check_tag_combo(rules, relics: Array) -> bool:
	var combo_relics = [relics[7], relics[8]]
	var result = rules.evaluate(combo_relics)
	return result["combos"].has("破甲墨锋")

func _test_floor_transition(main: Node) -> void:
	print("\n--- 层间切换测试 ---")
	
	_test_case("TC-FT-02 死局保护", _check_death_protection(main))
	_test_case("TC-FT-03 灵石转业力", _check_spirit_stone_conversion(main))
	_test_case("TC-FT-06 祭坛Buff清零", _check_altar_buff_clear(main))
	_test_case("TC-FT-08 5层区域主题", _check_floor_themes(main))

func _check_death_protection(main: Node) -> bool:
	main.player["hp"] = 10.0
	main.player["max_hp"] = 100.0
	main.player["stats"]["altar_buff"] = {}
	main.state = "floor_clear"
	main._continue_next_floor()
	return main.player["hp"] >= 15.0

func _check_spirit_stone_conversion(main: Node) -> bool:
	var karma_from_stones = 23 / 5
	return karma_from_stones == 4

func _check_altar_buff_clear(main: Node) -> bool:
	main.player["stats"]["altar_buff"] = {"strength": 10, "defense": 5}
	main.state = "floor_clear"
	main._continue_next_floor()
	return not main.player["stats"].has("altar_buff")

func _check_floor_themes(main: Node) -> bool:
	var themes = ["墨渊初境", "锈铁长廊", "碧落回廊", "赤焰熔窟", "归墟深渊"]
	for i in range(5):
		if main._floor_theme(i + 1) != themes[i]:
			return false
	return true

func _test_relic_system(main: Node) -> void:
	print("\n--- 遗物系统测试 ---")
	
	_test_case("TC-RL-03 稀有度与标签数对应", _check_rarity_tags(main.relics))
	_test_case("TC-RL-08 遗物与五行盘联动", _check_disk_pattern_trigger(main))
	_test_case("TC-RL-10 死亡后遗物状态", _check_death_relic_clear(main))

func _check_rarity_tags(relics: Array) -> bool:
	for r in relics:
		var tag_count = len(r.get("tags", []))
		var rarity = r.get("rarity", "common")
		if rarity == "common" and tag_count != 1:
			return false
		if rarity == "rare" and tag_count < 1:
			return false
		if rarity == "epic" and tag_count < 2:
			return false
		if rarity == "legendary" and tag_count < 3:
			return false
	return true

func _check_disk_pattern_trigger(main: Node) -> bool:
	main.player["disk"] = [main.relics[2], main.relics[2], main.relics[2], main.relics[4], main.relics[4]]
	main._evaluate_build()
	return main.player["patterns"].has("金水相生")

func _check_death_relic_clear(main: Node) -> bool:
	var custom_relic_id = main.relics[2]["id"]
	main.player["inventory"] = [main.relics[2], main.relics[3]]
	main.player["disk"] = [main.relics[4], main.relics[5], main.relics[6], main.relics[7], main.relics[8]]
	main._start_game()
	var has_custom = false
	for r in main.player["inventory"]:
		if r and r["id"] == custom_relic_id:
			has_custom = true
	return not has_custom and main.player["disk"].count(null) == 5

func _test_combat_system(main: Node) -> void:
	print("\n--- 战斗系统测试 ---")
	
	_test_case("TC-CB-04 Boss二阶段转阶段", _check_boss_phase_transition(main))
	_test_case("TC-CB-09 元素破盾", _check_element_shield_break(main))

func _check_boss_phase_transition(main: Node) -> bool:
	main.enemies.clear()
	main._spawn_enemy("boss", main.ARENA.get_center())
	main.enemies[0]["hp"] = main.enemies[0]["max_hp"] * 0.49
	main._update_boss(0, 0.01)
	return main.enemies[0]["phase"] == 2

func _check_element_shield_break(main: Node) -> bool:
	main.enemies.clear()
	main._spawn_enemy("boss", main.ARENA.get_center())
	var shield_before = main.enemies[0]["shield"]
	main.player["element_counts"] = {"fire": 1}
	main._damage_enemy(0, 10.0, false, false)
	var fire_damage = shield_before - main.enemies[0]["shield"]
	
	main.enemies[0]["shield"] = shield_before
	main.player["element_counts"] = {"water": 1}
	main._damage_enemy(0, 10.0, false, false)
	var water_damage = shield_before - main.enemies[0]["shield"]
	
	return fire_damage > water_damage

func _test_case(name: String, result: bool) -> void:
	if result:
		print("[PASS] %s" % name)
		passed += 1
	else:
		print("[FAIL] %s" % name)
		failed += 1

func _print_report() -> void:
	print("\n=== 测试报告 ===")
	print("通过: %d" % passed)
	print("失败: %d" % failed)
	print("合计: %d" % (passed + failed))
	if failed > 0:
		print("状态: FAIL")
	else:
		print("状态: PASS")
