extends RefCounted

var main = null

func _init(main_node):
	main = main_node

# --- 信号回调 ---
func _on_player_damaged(amount: float, current_hp: float):
	if main == null:
		return
	# 受击时自动触发顿帧（不覆盖已有的更长顿帧）
	if main.hit_stop_time < 0.06:
		main.hit_stop_time = 0.06

func _on_enemy_killed(kind: String, pos: Vector2):
	if main == null:
		return
	# 击杀时自动触发额外震屏
	var intensity := 12.0 if kind == "boss" else 6.0
	main.screen_shake = Vector2((randf() - 0.5) * intensity, (randf() - 0.5) * intensity)

func update(delta: float):
	if main == null:
		return
	main._update_combat_feedback(delta)

func get_hit_stop_time() -> float:
	if main == null:
		return 0.0
	return main.hit_stop_time

func get_screen_shake() -> Vector2:
	if main == null:
		return Vector2.ZERO
	return main.screen_shake

func get_particles() -> Array:
	if main == null:
		return []
	return main.particles

func get_float_texts() -> Array:
	if main == null:
		return []
	return main.float_texts

func get_impact_effects() -> Array:
	if main == null:
		return []
	return main.impact_effects

func get_death_actors() -> Array:
	if main == null:
		return []
	return main.death_actors

func trigger_hit_stop(duration: float = 0.1):
	if main == null:
		return
	main.hit_stop_time = duration

func trigger_screen_shake(intensity: float = 8.0):
	if main == null:
		return
	main.screen_shake = Vector2((randf() - 0.5) * intensity, (randf() - 0.5) * intensity)

func spawn_particle(pos: Vector2, color: Color, speed: float = 60.0, life: float = 0.8):
	if main == null:
		return
	var angle := randf() * TAU
	main.particles.append({
		"pos": Vector2(pos.x, pos.y),
		"vel": Vector2(cos(angle), sin(angle)) * speed,
		"life": life,
		"color": color,
		"radius": 3.0 + randf() * 3.0,
	})

func spawn_ink(pos: Vector2, color: Color, count: int = 8):
	if main == null:
		return
	for i in range(count):
		spawn_particle(pos, color)

func add_float_text(pos: Vector2, text: String, color: Color):
	if main == null:
		return
	main.float_texts.append({
		"pos": Vector2(pos.x, pos.y),
		"text": text,
		"color": color,
		"life": 1.2,
	})

func add_impact(pos: Vector2, kind: String, color: Color):
	if main == null:
		return
	main.impact_effects.append({
		"pos": Vector2(pos.x, pos.y),
		"kind": kind,
		"color": color,
		"ttl": 0.5,
		"duration": 0.5,
	})

func add_death_actor(pos: Vector2, kind: String, element: String):
	if main == null:
		return
	main.death_actors.append({
		"pos": Vector2(pos.x, pos.y),
		"kind": kind,
		"element": element,
		"ttl": 2.0,
	})

func clear_all():
	if main == null:
		return
	main.particles.clear()
	main.float_texts.clear()
	main.impact_effects.clear()
	main.death_actors.clear()
	main.hit_stop_time = 0.0
	main.screen_shake = Vector2.ZERO
