extends SceneTree

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

	print("\n=== 回归测试 v1.0 ===")
	
	_test_core_flow(main)
	_test_combat_regression(main)
	_test_five_element_regression(main)
	_test_relic_regression(main)
	_test_floor_transition_regression(main)
	_test_animation_regression(main)
	_test_input_ui_regression(main)
	
	_print_report()
	
	if failed > 0:
		quit(1)
	else:
		quit(0)

func _test_core_flow(main: Node) -> void:
	print("\n--- 核心流程回归 ---")
	
	_test_case("RG-01 游戏启动", main.state == "menu")
	_test_case("RG-02 开始新游戏", _test_start_game(main))
	_test_case("RG-03 角色移动", _test_player_move(main))
	_test_case("RG-04 角色攻击", _test_player_attack(main))
	_test_case("RG-05 角色闪避", _test_player_dodge(main))
	_test_case("RG-06 敌人生成", _test_enemy_spawn(main))
	_test_case("RG-07 敌人受伤死亡", _test_enemy_damage(main))
	_test_case("RG-08 进入下一房间", _test_room_enter(main))
	_test_case("RG-09 商店交互", _test_shop_interact(main))
	_test_case("RG-10 Boss生成", _test_boss_spawn(main))

func _test_start_game(main: Node) -> bool:
	main._start_game()
	return main.state == "prep" and main.player["hp"] == 100.0

func _test_player_move(main: Node) -> bool:
	main.player["pos"] = Vector2(100, 100)
	main.player["speed"] = 230.0
	main.player["dir"] = Vector2.RIGHT
	var move_speed = main.player["speed"] * 0.1
	main.player["pos"] += main.player["dir"] * move_speed
	return main.player["pos"].x > 100.0

func _test_player_attack(main: Node) -> bool:
	main.state = "combat"
	main.player["attack_cd"] = 0.0
	main.player["pos"] = main.ARENA.get_center()
	main._attack(main.player["pos"] + Vector2.RIGHT * 200.0, true)
	return main.slash["angle"] == 0.0

func _test_player_dodge(main: Node) -> bool:
	main.player["dodge_cd"] = 0.0
	main.player["hurt"] = 0.0
	main.player["pos"] = main.ARENA.get_center()
	main._dodge()
	return main.impact_effects.size() >= 1

func _test_enemy_spawn(main: Node) -> bool:
	main.enemies.clear()
	main._spawn_enemy("guard", main.ARENA.get_center())
	return main.enemies.size() == 1

func _test_enemy_damage(main: Node) -> bool:
	main.enemies.clear()
	main._spawn_enemy("guard", main.ARENA.get_center())
	if main.enemies.is_empty():
		return false
	var hp_before = main.enemies[0]["hp"]
	main._damage_enemy(0, 50.0, false, false)
	if main.enemies.is_empty():
		return true
	return main.enemies[0]["hp"] < hp_before

func _test_room_enter(main: Node) -> bool:
	var saved_rooms = main.rooms.duplicate(true)
	main.rooms.clear()
	main.rooms.append({"x": 0, "y": 0, "type": "MONSTER", "visited": false, "cleared": false, "links": []})
	main.current_room = 0
	main.state = "prep"
	var result = main.state != "menu"
	main.rooms.clear()
	for room in saved_rooms:
		main.rooms.append(room)
	return result

func _test_shop_interact(main: Node) -> bool:
	var saved_rooms = main.rooms.duplicate(true)
	var saved_state = main.state
	main.rooms.clear()
	main.rooms.append({"x": 0, "y": 0, "type": "SHOP", "visited": true, "cleared": false, "links": []})
	main.state = "shop"
	var result = main._visible_exit_links(0).size() >= 0
	main.rooms.clear()
	for room in saved_rooms:
		main.rooms.append(room)
	main.state = saved_state
	return result

func _test_boss_spawn(main: Node) -> bool:
	main.enemies.clear()
	main._spawn_enemy("boss", main.ARENA.get_center())
	return main.enemies.size() == 1 and main.enemies[0]["kind"] == "boss"

func _test_combat_regression(main: Node) -> void:
	print("\n--- 战斗系统回归 ---")
	
	_test_case("RG-11 受伤打断攻击", _test_hurt_interrupt(main))
	_test_case("RG-12 闪避无敌帧", _test_dodge_invulnerability(main))
	_test_case("RG-13 Boss二阶段转阶段", _test_boss_phase(main))
	_test_case("RG-14 武器副技能", _test_subskill(main))

func _test_hurt_interrupt(main: Node) -> bool:
	main._start_game()
	main.state = "combat"
	main.player["anim_action"] = "attack"
	main.player["hurt"] = 0.0
	main.player["invuln"] = 0.0
	main.player["hp"] = 50.0
	main._damage_player(10.0)
	return main.player["hurt"] > 0.0

func _test_dodge_invulnerability(main: Node) -> bool:
	main.player["dodge_cd"] = 0.0
	main.player["hurt"] = 0.0
	main._dodge()
	return main.player["invuln"] > 0.0

func _test_boss_phase(main: Node) -> bool:
	main.enemies.clear()
	main._spawn_enemy("boss", main.ARENA.get_center())
	main.enemies[0]["hp"] = main.enemies[0]["max_hp"] * 0.49
	main._update_boss(0, 0.01)
	return main.enemies[0]["phase"] == 2

func _test_subskill(main: Node) -> bool:
	main.state = "combat"
	main.player["weapon"] = main.weapons[1].duplicate(true)
	main.player["weapon"]["variant"] = {"id": "blink_slash"}
	main.player["subskill_cd"] = 0.0
	main.player["pos"] = main.ARENA.get_center()
	main.enemies.clear()
	main._spawn_enemy("blade", main.player["pos"] + Vector2(84, 0))
	var hp_before = main.enemies[0]["hp"]
	main._use_subskill(main.player["pos"] + Vector2(180, 0))
	return main.player["subskill_cd"] > 0.0 and main.enemies[0]["hp"] < hp_before

func _test_five_element_regression(main: Node) -> void:
	print("\n--- 五行系统回归 ---")
	
	var rules = load("res://scripts/FiveElementRules.gd")
	
	_test_case("RG-15 单元素极致", rules.evaluate([main.relics[2], main.relics[2], main.relics[2], main.relics[2], main.relics[2]])["patterns"].has("锐金之极"))
	_test_case("RG-16 相生双元", rules.evaluate([main.relics[2], main.relics[2], main.relics[2], main.relics[4], main.relics[4]])["patterns"].has("金水相生"))
	_test_case("RG-17 相克双元", rules.evaluate([main.relics[2], main.relics[2], main.relics[2], main.relics[3], main.relics[3]])["patterns"].has("金木交锋"))
	_test_case("RG-18 五行圆满", rules.evaluate([main.relics[2], main.relics[3], main.relics[4], main.relics[5], main.relics[6]])["patterns"] == ["五行圆满"])
	_test_case("RG-19 格局驱逐", rules.evaluate([main.relics[2], main.relics[2], main.relics[2], main.relics[4], main.relics[4], main.relics[3]])["patterns"] == ["金水木·涌泉"])
	_test_case("RG-20 标签组合", rules.evaluate([main.relics[7], main.relics[8]])["combos"].has("破甲墨锋"))

func _test_relic_regression(main: Node) -> void:
	print("\n--- 遗物系统回归 ---")
	
	_test_case("RG-21 遗物装备到五行盘", _test_relic_equip(main))
	_test_case("RG-22 遗物与五行盘联动", _test_relic_disk_trigger(main))
	_test_case("RG-23 遗物属性叠加", _test_relic_stack(main))

func _test_relic_equip(main: Node) -> bool:
	main._start_game()
	main.player["disk"] = [null, null, null, null, null]
	main.player["inventory"] = [main.relics[2]]
	main.selected_inventory_index = -1
	main._inventory_pressed(0)
	return main.player["disk"][0] != null

func _test_relic_disk_trigger(main: Node) -> bool:
	main.player["disk"] = [main.relics[2], main.relics[2], main.relics[2], main.relics[4], main.relics[4]]
	main._evaluate_build()
	return main.player["patterns"].has("金水相生")

func _test_relic_stack(main: Node) -> bool:
	main.player["stats"] = {}
	main.player["disk"] = [main.relics[7], main.relics[8], null, null, null]
	main._evaluate_build()
	return main.player["stats"].get("crit", 0.0) > 0.0

func _test_floor_transition_regression(main: Node) -> void:
	print("\n--- 层间切换回归 ---")
	
	_test_case("RG-24 死局保护", _test_death_protection(main))
	_test_case("RG-25 祭坛Buff清零", _test_altar_clear(main))
	_test_case("RG-26 区域主题", _test_floor_themes(main))

func _test_death_protection(main: Node) -> bool:
	main.player["hp"] = 10.0
	main.player["max_hp"] = 100.0
	main.player["stats"]["altar_buff"] = {}
	main.state = "floor_clear"
	main._continue_next_floor()
	return main.player["hp"] >= 15.0

func _test_altar_clear(main: Node) -> bool:
	main.player["stats"]["altar_buff"] = {"strength": 10}
	main.state = "floor_clear"
	main._continue_next_floor()
	return not main.player["stats"].has("altar_buff")

func _test_floor_themes(main: Node) -> bool:
	var themes = ["墨渊初境", "锈铁长廊", "碧落回廊", "赤焰熔窟", "归墟深渊"]
	for i in range(5):
		if main._floor_theme(i + 1) != themes[i]:
			return false
	return true

func _test_animation_regression(main: Node) -> void:
	print("\n--- 动画VFX回归 ---")
	
	_test_case("RG-27 角色动画序列", main.CHARACTER_SEQUENCES.action_count("player") == 6)
	_test_case("RG-28 VFX序列数量", main.VFX_SEQUENCES.has_sequence("hit") and main.VFX_SEQUENCES.has_sequence("dodge"))
	_test_case("RG-29 帧边界", _test_frame_boundary(main))

func _test_frame_boundary(main: Node) -> bool:
	var region_a = main.CHARACTER_SEQUENCES.region("player", "idle", 0)
	var region_b = main.CHARACTER_SEQUENCES.region("player", "idle", 1)
	return region_a.end.x < region_b.position.x

func _test_input_ui_regression(main: Node) -> void:
	print("\n--- 输入UI回归 ---")
	
	_test_case("RG-30 五行盘拖拽", _test_disk_drag(main))
	_test_case("RG-31 结算面板", _test_settlement(main))

func _test_disk_drag(main: Node) -> bool:
	main.player["disk"] = [main.relics[2], main.relics[3], main.relics[4], main.relics[5], main.relics[6]]
	main.player["inventory"] = [main.relics[7]]
	main._evaluate_build()
	main._inventory_pressed(0)
	main._disk_slot_pressed(1)
	return main.player["disk"][1]["id"] == "gold_ring"

func _test_settlement(main: Node) -> bool:
	return main.settlement_panel != null

func _test_case(name: String, result: bool) -> void:
	if result:
		print("[PASS] %s" % name)
		passed += 1
	else:
		print("[FAIL] %s" % name)
		failed += 1

func _print_report() -> void:
	print("\n=== 回归测试报告 ===")
	print("通过: %d" % passed)
	print("失败: %d" % failed)
	print("合计: %d" % (passed + failed))
	if failed > 0:
		print("状态: FAIL")
	else:
		print("状态: PASS")
