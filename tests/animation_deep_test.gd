extends SceneTree


func _initialize() -> void:
	var packed := load("res://scenes/Main.tscn")
	if packed == null:
		_fail("Main scene failed to load.")
		return
	var main: Node = packed.instantiate()
	root.add_child(main)
	await process_frame

	var vfx_checked := _validate_vfx(main)
	if vfx_checked < 0:
		return
	var character_states := _validate_characters(main)
	if character_states < 0:
		return
	if not await _validate_interruptions(main):
		return
	if ProjectSettings.get_setting("display/window/stretch/aspect") != "keep":
		_fail("Expected a fixed 16:9 design canvas so viewport resizing cannot skew world-to-effect mapping.")
		return

	print("ANIMATION_DEEP_OK vfx=%d character_states=%d" % [vfx_checked, character_states])
	quit(0)


func _validate_vfx(main: Node) -> int:
	var checked := 0
	for kind_value in main.VFX_SEQUENCES.ROWS.keys():
		var kind: String = kind_value
		if not main.VFX_SEQUENCES.atlas_matches_texture(kind):
			_fail("VFX atlas metadata does not match loaded texture: %s" % kind)
			return -1
		var active_frames: int = main.VFX_SEQUENCES.frame_count(kind)
		var previous_frame := -1
		var previous_region := Rect2()
		for step in range(33):
			var duration := 0.05 if step % 2 == 0 else 1.4
			var progress := float(step) / 32.0
			var sample: Dictionary = main._sequence_sample(duration * (1.0 - progress), duration, active_frames)
			if sample["frame"] < previous_frame and step % 2 == 0:
				_fail("VFX frame order regressed for %s." % kind)
				return -1
			if step % 2 == 0:
				previous_frame = sample["frame"]
		for frame in range(main.VFX_SEQUENCES.FRAMES):
			var region: Rect2 = main.VFX_SEQUENCES.region(kind, frame)
			var texture_size: Vector2 = main.VFX_SEQUENCES.texture(kind).get_size()
			if region.size.x <= 0.0 or region.size.y <= 0.0 or region.position.x < 0.0 or region.position.y < 0.0 or region.end.x > texture_size.x or region.end.y > texture_size.y:
				_fail("VFX region is outside its loaded atlas: %s frame %d." % [kind, frame])
				return -1
			if frame > 0 and previous_region.end.x >= region.position.x:
				_fail("VFX frame regions overlap: %s frame %d." % [kind, frame])
				return -1
			previous_region = region
			var anchor: Vector2 = main.VFX_SEQUENCES.anchor(kind, frame)
			if anchor.x < 0.0 or anchor.x > 1.0 or anchor.y < 0.0 or anchor.y > 1.0:
				_fail("VFX anchor is invalid: %s frame %d -> %s." % [kind, frame, anchor])
				return -1
			var size := Vector2(233.0, 117.0)
			var rect: Rect2 = main._vfx_frame_rect(kind, frame, size)
			var local_anchor := rect.position + anchor * rect.size
			for viewport_scale in [Vector2(0.5, 0.5), Vector2(1.0, 1.0), Vector2(1.75, 1.75)]:
				var transform := Transform2D(0.83, viewport_scale, 0.0, Vector2(437.0, 281.0))
				if local_anchor.length() > 0.001 or (transform * local_anchor).distance_to(transform.origin) > 0.001:
					_fail("VFX anchor moved under stretch/rotation/viewport scaling: %s frame %d." % [kind, frame])
					return -1
		checked += 1
	return checked


func _validate_characters(main: Node) -> int:
	var state_count := 0
	for kind_value in main.CHARACTER_SEQUENCES.SPECS.keys():
		var kind: String = kind_value
		if not main.CHARACTER_SEQUENCES.atlas_matches_texture(kind):
			_fail("Character atlas metadata does not match loaded texture: %s" % kind)
			return -1
		var actions: Dictionary = main.CHARACTER_SEQUENCES.SPECS[kind]["actions"]
		for action_value in actions.keys():
			var action: String = action_value
			var previous_region := Rect2()
			for frame in range(main.CHARACTER_SEQUENCES.frame_count(kind)):
				var region: Rect2 = main.CHARACTER_SEQUENCES.region(kind, action, frame)
				var texture_size: Vector2 = main.CHARACTER_SEQUENCES.texture(kind).get_size()
				if region.size.x <= 0.0 or region.size.y <= 0.0 or region.position.x < 0.0 or region.position.y < 0.0 or region.end.x > texture_size.x or region.end.y > texture_size.y:
					_fail("Character region is outside its atlas: %s/%s frame %d." % [kind, action, frame])
					return -1
				if kind == "elite" and frame > 0 and previous_region.end.x >= region.position.x:
					_fail("Elite custom frame regions overlap: %s frame %d." % [action, frame])
					return -1
				previous_region = region
				var anchor: Vector2 = main.CHARACTER_SEQUENCES.anchor(kind, action, frame)
				var draw_size: Vector2 = main.CHARACTER_SEQUENCES.frame_draw_size(kind, action, frame)
				if anchor.x < 0.0 or anchor.x > 1.0 or anchor.y < 0.0 or anchor.y > 1.0 or draw_size.x <= 0.0 or draw_size.y <= 0.0:
					_fail("Character frame metadata is invalid: %s/%s frame %d." % [kind, action, frame])
					return -1
				var local_anchor := -anchor * draw_size + anchor * draw_size
				if local_anchor.length() > 0.001:
					_fail("Character foot anchor does not map to actor origin: %s/%s frame %d." % [kind, action, frame])
					return -1
			state_count += 1
	return state_count


func _validate_interruptions(main: Node) -> bool:
	main._start_game()
	await process_frame
	main.player["loop_action"] = "idle"
	main.player["loop_clock"] = 0.75
	main._advance_player_loop("run", 0.016)
	if main.player["loop_action"] != "run" or main.player["loop_clock"] != 0.0:
		_fail("Player idle-to-run transition did not restart at frame zero.")
		return false
	main._advance_player_loop("run", 0.016)
	if not is_equal_approx(main.player["loop_clock"], 0.016):
		_fail("Player run loop did not advance on its independent clock.")
		return false
	main._set_player_animation("attack", 0.20)
	main.player["anim_time"] = 0.04
	main._set_player_animation("attack", 0.20)
	var restarted: Dictionary = main._character_sample("player", "attack", main.player["anim_time"], main.player["anim_duration"])
	if restarted["frame"] != 0:
		_fail("Rapid player attack retrigger did not restart at frame zero.")
		return false

	main.state = "combat"
	main.enemies.clear()
	main._spawn_enemy("elite", main.ARENA.get_center())
	var elite: Dictionary = main.enemies[0]
	elite["anim_action"] = "attack"
	elite["anim_time"] = 0.30
	elite["anim_duration"] = 0.42
	main._damage_enemy(0, 1.0, false, false)
	if elite["hurt"] <= 0.0 or elite["anim_action"] != "hurt" or elite["anim_time"] != 0.0 or main._enemy_animation_action(elite) != "hurt":
		_fail("Enemy hurt did not cleanly interrupt a timed attack.")
		return false
	var hurt_before: float = elite["hurt"]
	main._damage_enemy(0, 1.0, false, false)
	if elite["hurt"] < hurt_before:
		_fail("Rapid hurt retrigger did not restart the hurt sequence.")
		return false
	elite["hurt"] = 0.0
	elite["anim_time"] = 0.0
	elite["moving"] = true
	elite["loop_action"] = "idle"
	elite["loop_clock"] = 0.9
	main._advance_enemy_loop(elite, 0.016)
	if elite["loop_action"] != "run" or elite["loop_clock"] != 0.0:
		_fail("Enemy hurt-to-run transition did not restart the locomotion loop.")
		return false

	main.impact_effects.clear()
	main._spawn_sequence_vfx("relic_get", Vector2(100, 100), 200.0, 0.0, 0.001)
	main._spawn_sequence_vfx("pattern_high", Vector2(200, 200), 220.0, 0.0, 0.001)
	if main.impact_effects.size() != 1 or main.impact_effects[0]["kind"] != "pattern_high" or main.impact_effects[0]["duration"] < 0.05:
		_fail("Rapid progression VFX interruption left stale state or an invalid duration.")
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
