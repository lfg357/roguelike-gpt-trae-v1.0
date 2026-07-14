extends SceneTree


func _initialize() -> void:
	var packed := load("res://scenes/Main.tscn")
	if packed == null:
		push_error("Main scene failed to load.")
		quit(1)
		return

	var main: Node = packed.instantiate()
	root.add_child(main)
	await process_frame
	if main.ui_theme == null or main.CHARACTER_SEQUENCES.texture("player") == null or main.VFX_SEQUENCES.texture("combo_1") == null or main.VFX_SEQUENCES.texture("hit") == null or main.VFX_SEQUENCES.texture("harmony") == null:
		push_error("Expected the P0 ink UI theme, Appendix G character sequences, and authored VFX sequences to load.")
		quit(1)
		return
	if main.CHARACTER_SEQUENCES.frame_count("player") != 8 or main.CHARACTER_SEQUENCES.action_count("player") != 6:
		push_error("Expected Yan Wugui to provide six Appendix G action rows with eight authored frames each.")
		quit(1)
		return
	if main.CHARACTER_SEQUENCES.action_count("blade") != 4 or main.CHARACTER_SEQUENCES.action_count("elite") != 5 or main.CHARACTER_SEQUENCES.frame_count("elite") != 7 or main.CHARACTER_SEQUENCES.action_count("boss") != 6:
		push_error("Expected P0 enemies, elite, and boss to meet their Appendix G action-group budgets.")
		quit(1)
		return
	if main.VFX_SEQUENCES.region("combo_3", 7).size.x <= 0.0 or main.VFX_SEQUENCES.region("shield_break", 7).size.y <= 0.0 or not main.VFX_SEQUENCES.has_sequence("harmony"):
		push_error("Expected independent eight-frame weapon, impact, and elemental VFX sequences.")
		quit(1)
		return
	if main.VFX_SEQUENCES.frame_count("combo_1") != 7 or main.VFX_SEQUENCES.frame_count("hit") != 7 or main.VFX_SEQUENCES.frame_count("dodge") != 8:
		push_error("Expected VFX playback to skip audited empty tail frames without changing authored atlas metadata.")
		quit(1)
		return
	var character_region_a: Rect2 = main.CHARACTER_SEQUENCES.region("player", "idle", 0)
	var character_region_b: Rect2 = main.CHARACTER_SEQUENCES.region("player", "idle", 1)
	var vfx_region_a: Rect2 = main.VFX_SEQUENCES.region("combo_1", 0)
	var vfx_region_b: Rect2 = main.VFX_SEQUENCES.region("combo_1", 1)
	if character_region_a.end.x >= character_region_b.position.x or vfx_region_a.end.x >= vfx_region_b.position.x:
		push_error("Expected padded integer atlas regions to prevent adjacent-frame sampling bleed.")
		quit(1)
		return
	if character_region_a.position != character_region_a.position.round() or vfx_region_a.position != vfx_region_a.position.round():
		push_error("Expected atlas sampling to use integer pixel boundaries.")
		quit(1)
		return
	if main.CHARACTER_SEQUENCES.anchor("player", "run", 0) == main.CHARACTER_SEQUENCES.anchor("player", "run", 2):
		push_error("Expected authored per-frame anchors for visible locomotion drift compensation.")
		quit(1)
		return
	if main.ARENA.size.x <= 758.0 or main.ARENA.size.y <= 482.0 or main.CHARACTER_SEQUENCES.draw_size("player").x >= 146.0:
		push_error("Expected the enlarged arena and rebalanced actor-to-world scale.")
		quit(1)
		return
	var transition_sample: Dictionary = main._sequence_sample(0.101, 0.20, 8)
	if transition_sample["next_frame"] < transition_sample["frame"] or transition_sample["phase"] < 0.0 or transition_sample["phase"] >= 1.0:
		push_error("Expected a valid adjacent-keyframe interpolation sample.")
		quit(1)
		return
	var dedicated_vfx := [
		"sword_wave", "blink_slash", "combo_haste",
		"ice_scar", "cold_flash", "frost_armor",
		"rainbow_cut", "ink_shadow", "return_blade",
		"mountain_cleave", "earth_quake", "iron_wall",
		"blood_rage", "soul_bite", "blood_shield",
		"relic_get", "weapon_get", "pattern_low", "pattern_mid", "pattern_high",
	]
	for vfx_kind in dedicated_vfx:
		if not main.VFX_SEQUENCES.has_sequence(vfx_kind) or main.VFX_SEQUENCES.region(vfx_kind, 7).size.x <= 0.0:
			push_error("Expected a dedicated authored sequence for %s." % vfx_kind)
			quit(1)
			return
	for frame_index in range(8):
		var sampled: Dictionary = main._sequence_sample(1.0 - float(frame_index) / 8.0, 1.0, 8)
		if sampled["frame"] != frame_index:
			push_error("Expected one-shot VFX frame sampling to advance in atlas order, got %s at step %d." % [sampled["frame"], frame_index])
			quit(1)
			return
	main.impact_effects.clear()
	main._spawn_sequence_vfx("relic_get", Vector2(100, 100), 200.0, 0.0, 0.0)
	main._spawn_sequence_vfx("pattern_high", Vector2(200, 200), 240.0, 0.0, 0.72)
	if main.impact_effects.size() != 1 or main.impact_effects[0]["kind"] != "pattern_high" or main.impact_effects[0].get("slot", "") != "progression":
		push_error("Expected pickup/progression VFX to reset the shared progression slot instead of leaving stale instances.")
		quit(1)
		return
	main._spawn_sequence_vfx("not_a_real_sequence", Vector2.ZERO, 100.0)
	if main.impact_effects.size() != 1:
		push_error("Expected invalid VFX kinds to be ignored without leaving broken draw state.")
		quit(1)
		return
	main.impact_effects.clear()

	main._start_game()
	await process_frame

	if main.state != "prep":
		push_error("Expected prep state after start.")
		quit(1)
		return
	main.state = "combat"
	main.enemies.clear()
	main.player["attack_cd"] = 0.0
	main.player["pos"] = main.ARENA.get_center()
	main._attack(main.player["pos"] + Vector2.RIGHT * 200.0, true)
	if absf(angle_difference(main.slash["angle"], 0.0)) > 0.001:
		push_error("Expected the right-authored slash to face a right-side mouse click.")
		quit(1)
		return
	main.player["attack_cd"] = 0.0
	main._attack(main.player["pos"] + Vector2.LEFT * 200.0, true)
	if absf(angle_difference(main.slash["angle"], PI)) > 0.001:
		push_error("Expected the slash direction to rotate directly toward a left-side mouse click.")
		quit(1)
		return
	main.state = "prep"
	main.player["pos"] = main.LORE_STELE_POS
	main._interact()
	if main.telemetry.count("lore_read") != 1:
		push_error("Expected START room lore stele to be readable.")
		quit(1)
		return

	main._toggle_disk(true)
	main._inventory_pressed(0)
	main._inventory_pressed(0)
	main._inventory_pressed(0)
	await process_frame

	if main.player["disk"].count(null) == 5:
		push_error("Expected relics to be placed on disk.")
		quit(1)
		return
	var saved_rooms: Array[Dictionary] = main.rooms.duplicate(true)
	var saved_state: String = main.state
	main.rooms.clear()
	main.rooms.append({"x": 1, "y": 1, "type": "SHOP", "visited": true, "cleared": false, "links": [1]})
	main.rooms.append({"x": 2, "y": 0, "type": "MONSTER", "visited": true, "cleared": true, "links": [0]})
	main.state = "shop"
	var diagonal_exit: Rect2 = main._exit_rect_for_link(0, 1)
	if diagonal_exit.position.x < main.ARENA.end.x - 73.0 or diagonal_exit.position.y != main.ARENA.position.y:
		push_error("Expected northeast map link to create a top-right room exit.")
		quit(1)
		return
	if main._visible_exit_links(0).is_empty():
		push_error("Expected shop to show an exit even when linked room is already cleared.")
		quit(1)
		return
	main.rooms.clear()
	for room in saved_rooms:
		main.rooms.append(room)
	main.state = saved_state

	main.player["disk"] = [main.relics[2], main.relics[3], main.relics[4], main.relics[5], main.relics[6]]
	main.player["inventory"] = [main.relics[7]]
	main._evaluate_build()
	main._inventory_pressed(0)
	if main.selected_inventory_index != 0:
		push_error("Expected full disk inventory click to select replacement candidate.")
		quit(1)
		return
	var replaced_id: String = main.player["disk"][1]["id"]
	main._disk_slot_pressed(1)
	if main.player["disk"][1]["id"] != "gold_ring" or main.player["inventory"][0]["id"] != replaced_id:
		push_error("Expected selected inventory relic to swap with disk slot.")
		quit(1)
		return

	var rules = load("res://scripts/FiveElementRules.gd")
	var rule_result: Dictionary = rules.evaluate([main.relics[2], main.relics[3]])
	if not rule_result["patterns"].has("金木交锋"):
		push_error("Expected metal+wood opposition pattern.")
		quit(1)
		return
	if rule_result["stats"].get("armor_damage", 0.0) <= 0.0:
		push_error("Expected opposition armor damage bonus.")
		quit(1)
		return
	var triple_result: Dictionary = rules.evaluate([main.relics[8], main.relics[10], main.relics[3]])
	if triple_result["patterns"] != ["金水木·涌泉"]:
		push_error("Expected dominant triple pattern to evict pair patterns, got %s." % [triple_result["patterns"]])
		quit(1)
		return
	var mixed_result: Dictionary = rules.evaluate([main.relics[11], main.relics[10], main.relics[3]])
	if mixed_result["patterns"] != ["火水木·蒸腾"]:
		push_error("Expected mixed triple pattern to dominate same-element chain, got %s." % [mixed_result["patterns"]])
		quit(1)
		return
	var quad_result: Dictionary = rules.evaluate([main.relics[7], main.relics[4], main.relics[5], main.relics[6]])
	if quad_result["patterns"] != ["金水火土·破界"]:
		push_error("Expected exact 4-element quad pattern, got %s." % [quad_result["patterns"]])
		quit(1)
		return
	var duplicate_quad_result: Dictionary = rules.evaluate([main.relics[7], main.relics[2], main.relics[4], main.relics[5], main.relics[6]])
	if duplicate_quad_result["patterns"].has("金水火土·破界"):
		push_error("Expected duplicate element counts to reject exact quad signature.")
		quit(1)
		return
	var five_result: Dictionary = rules.evaluate([main.relics[2], main.relics[3], main.relics[4], main.relics[5], main.relics[6]])
	if five_result["patterns"] != ["五行圆满"]:
		push_error("Expected all five to only trigger 五行圆满, got %s." % [five_result["patterns"]])
		quit(1)
		return
	if five_result["stats"].get("all", 0.0) > 0.0 or five_result["stats"].get("damage", 0.0) > 0.06:
		push_error("Expected 五行圆满 to be a small balanced bonus, not a large all-stat spike.")
		quit(1)
		return
	if five_result["stats"].get("yuan_pulse", 0.0) <= 0.0:
		push_error("Expected 五行圆满 to enable a small归元脉冲.")
		quit(1)
		return

	var tag_combo_test: Dictionary = rules.evaluate([main.relics[7], main.relics[8]])
	if not tag_combo_test["combos"].has("破甲墨锋"):
		push_error("Expected tag combo 破甲墨锋 for 锐+裂.")
		quit(1)
		return
	if not tag_combo_test["combos"].has("焰刃"):
		push_error("Expected tag combo 焰刃 for 焚+锐.")
		quit(1)
		return
	var tag_count_test: Dictionary = rules.evaluate([main.relics[7], main.relics[10], main.relics[12]])
	if tag_count_test["combos"].size() < 2:
		push_error("Expected multiple tag combos from relics with overlapping tags.")
		quit(1)
		return

	main.enemies.clear()
	main._spawn_enemy("guard", main.ARENA.get_center() + Vector2(70, 0))
	main.enemies[0]["loop_clock"] = 0.125
	main.animation_clock = 9.0
	var guard_sample_a: Dictionary = main._enemy_animation_sample(main.enemies[0], "run")
	main.animation_clock = 21.0
	var guard_sample_b: Dictionary = main._enemy_animation_sample(main.enemies[0], "run")
	if guard_sample_a["frame"] != guard_sample_b["frame"] or guard_sample_a["phase"] != guard_sample_b["phase"]:
		push_error("Expected enemy looping animation to sample from per-enemy loop_clock, not global animation_clock.")
		quit(1)
		return
	main.enemies.clear()
	main._spawn_enemy("boss", main.ARENA.get_center())
	main.player["element_counts"] = {"metal": 0, "wood": 0, "water": 0, "fire": 0, "earth": 0}
	var shield_before: float = main.enemies[0]["shield"]
	main._damage_enemy(0, 10.0, false, false)
	var no_fire_shield_damage: float = shield_before - main.enemies[0]["shield"]
	if main.impact_effects.is_empty() or main.impact_effects.back()["kind"] != "metal":
		push_error("Expected a metal impact effect when striking the boss shield.")
		quit(1)
		return
	main.impact_effects.clear()
	main.player["dodge_cd"] = 0.0
	main.player["hurt"] = 0.0
	main.player["pos"] = main.ARENA.get_center()
	main.player["facing"] = 0.0
	main._dodge()
	if main.impact_effects.size() != 1 or main.impact_effects[0]["kind"] != "dodge" or main.impact_effects[0].has("atlas"):
		push_error("Expected dodge to use one dedicated authored sequence without layered atlas stamps.")
		quit(1)
		return
	main.enemies[0]["shield"] = shield_before
	main.player["element_counts"]["fire"] = 1
	main._damage_enemy(0, 10.0, false, false)
	var fire_shield_damage: float = shield_before - main.enemies[0]["shield"]
	if not is_equal_approx(fire_shield_damage, no_fire_shield_damage * 2.0):
		push_error("Expected fire build to deal double damage to metal boss shield.")
		quit(1)
		return
	main.enemies[0]["shield"] = 0.0
	main.enemies[0]["hp"] = main.enemies[0]["max_hp"] * 0.49
	main._update_boss(0, 0.01)
	if main.enemies[0]["phase"] != 2 or main.enemies[0]["element"] != "wood":
		push_error("Expected boss to switch to wood phase below 50%% HP.")
		quit(1)
		return
	if main.boss_pillars.size() != 4:
		push_error("Expected four replacement pillars in boss phase two.")
		quit(1)
		return
	main.enemies.clear()
	main.boss_pillars.clear()
	main.boss_hazards.clear()

	var rolled_weapon: Dictionary = main._roll_weapon(main.weapons[1])
	if rolled_weapon.get("variant", {}).is_empty():
		push_error("Expected rolled formal weapon to include a subskill variant.")
		quit(1)
		return
	main.state = "combat"
	main.player["weapon"] = main.weapons[1].duplicate(true)
	main.player["weapon"]["variant"] = {"id": "blink_slash", "name": "瞬步斩", "desc": "测试副技能"}
	main.player["subskill_cd"] = 0.0
	main.player["pos"] = main.ARENA.get_center()
	main.enemies.clear()
	main._spawn_enemy("blade", main.player["pos"] + Vector2(84, 0))
	main.impact_effects.clear()
	var enemy_hp_before: float = main.enemies[0]["hp"]
	main._use_subskill(main.player["pos"] + Vector2(180, 0))
	if main.player["subskill_cd"] <= 0.0 or main.enemies[0]["hp"] >= enemy_hp_before:
		push_error("Expected weapon subskill to enter cooldown and damage the enemy.")
		quit(1)
		return
	var blink_count := 0
	for effect in main.impact_effects:
		if effect["kind"] == "blink_slash":
			blink_count += 1
		if effect["kind"] == "dodge" or effect["kind"] == "death":
			push_error("Expected blink slash to avoid unrelated generic dodge/death layers.")
			quit(1)
			return
	if blink_count != 1:
		push_error("Expected blink slash to spawn exactly one dedicated skill sequence.")
		quit(1)
		return
	main.enemies.clear()
	main.state = "prep"

	var exits: Array[int] = main._available_exit_links(main.current_room)
	if exits.is_empty():
		push_error("Expected at least one exit from start room.")
		quit(1)
		return
	main.player["pos"] = main._exit_rect_for_link(main.current_room, exits[0]).get_center()
	main._interact()
	await process_frame
	if main.state == "menu":
		push_error("Expected to leave menu/prep flow.")
		quit(1)
		return
	if main.telemetry.count("run_start") != 1:
		push_error("Expected run_start telemetry event.")
		quit(1)
		return
	if main.telemetry.count("room_enter") < 1:
		push_error("Expected room_enter telemetry event.")
		quit(1)
		return
	main.drops.append({"type": "weapon", "item": main.weapons[1], "pos": main.player["pos"]})
	main._interact()
	await process_frame
	if not main.weapon_choice_panel.visible:
		push_error("Expected weapon choice panel before replacing weapon.")
		quit(1)
		return
	if main.weapon_choice_panel.size.y < 380.0 or main.weapon_choice_label.custom_minimum_size.y < 240.0:
		push_error("Expected weapon choice details to have enough vertical space.")
		quit(1)
		return
	main._decline_pending_weapon()
	await process_frame

	main.state = "shop"
	main.player["stones"] = 220
	main.player["inventory"] = []
	main.shop_stock.clear()
	main.shop_stock.append({"type": "relic", "item": main.relics[2], "price": 30, "sold": false})
	main.shop_stock.append({"type": "weapon", "item": main._roll_weapon(main.weapons[1]), "price": 80, "sold": false})
	main.rooms[main.current_room]["shop_stock"] = main.shop_stock
	main._refresh_shop_ui()
	main._shop_buy(1)
	if main.player["inventory"].is_empty() or main.player["stones"] != 190 or not main.shop_stock[0]["sold"]:
		push_error("Expected shop item purchase to add relic, spend stones, and mark sold.")
		quit(1)
		return
	var stones_before_sell: int = main.player["stones"]
	main._sell_inventory_item(0)
	if main.player["stones"] <= stones_before_sell or not main.player["inventory"].is_empty():
		push_error("Expected selling an inventory relic to return stones and remove the item.")
		quit(1)
		return
	main.state = "combat"

	main.player["hp"] = 5.0
	main._spawn_room("BOSS")
	if main.player["hp"] < main.player["max_hp"] * 0.30:
		push_error("Expected boss pre-heal to restore at least 30%% max HP.")
		quit(1)
		return
	main.current_room = 0
	main.rooms[0]["type"] = "BOSS"
	main.current_floor = 1
	main.player["karma"] = 0
	main.state = "combat"
	main.enemies.clear()
	main.boss_portal = {}
	main._clear_room()
	if main.state != "reward" or main.boss_portal.is_empty() or main.settlement_panel.visible:
		push_error("Expected boss clear to open a vortex portal before settlement.")
		quit(1)
		return
	if main.current_floor != 1 or main.player["karma"] != 0:
		push_error("Expected floor advancement and karma to wait for vortex interaction.")
		quit(1)
		return
	main.player["pos"] = main.boss_portal["pos"]
	main._interact()
	if not main.settlement_panel.visible:
		push_error("Expected vortex interaction to show floor settlement panel.")
		quit(1)
		return
	main._continue_next_floor()
	if main.state != "prep" and main.state != "explore":
		push_error("Expected settlement continue to generate the next floor.")
		quit(1)
		return
	main.state = "combat"
	main.player["hp"] = 1.0
	main.player["hurt"] = 0.0
	main.player["invuln"] = 0.0
	main._damage_player(999.0)
	if main.state != "dead" or not main.run_result_panel.visible:
		push_error("Expected death to show run result panel.")
		quit(1)
		return
	if main.telemetry.count("run_end") < 1:
		push_error("Expected run_end telemetry after death.")
		quit(1)
		return

	print("SMOKE_OK state=%s floor=%d rooms=%d" % [main.state, main.current_floor, main.rooms.size()])
	quit(0)
