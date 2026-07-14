extends RefCounted

const INK_THEME = preload("res://scripts/ui/InkTheme.gd")
const CHARACTER_SEQUENCES = preload("res://scripts/art/CharacterSequences.gd")

var main = null

func _init(main_node):
	main = main_node

func setup(initial_player: Dictionary):
	main.player = initial_player

func update_timers(delta: float):
	if main == null or main.player == null:
		return
	var player: Dictionary = main.player
	if player.get("attack_cd", 0.0) > 0.0:
		player["attack_cd"] = maxf(0.0, player["attack_cd"] - delta)
	if player.get("subskill_cd", 0.0) > 0.0:
		player["subskill_cd"] = maxf(0.0, player["subskill_cd"] - delta)
	if player.get("dodge_cd", 0.0) > 0.0:
		player["dodge_cd"] = maxf(0.0, player["dodge_cd"] - delta)
	if player.get("invuln", 0.0) > 0.0:
		player["invuln"] = maxf(0.0, player["invuln"] - delta)
	if player.get("hurt", 0.0) > 0.0:
		player["hurt"] = maxf(0.0, player["hurt"] - delta)
	if player.get("haste", 0.0) > 0.0:
		player["haste"] = maxf(0.0, player["haste"] - delta)
	if player.get("guard", 0.0) > 0.0:
		player["guard"] = maxf(0.0, player["guard"] - delta)
	if player.get("rage", 0.0) > 0.0:
		player["rage"] = maxf(0.0, player["rage"] - delta)
	if player.get("anim_time", 0.0) > 0.0:
		player["anim_time"] = maxf(0.0, player["anim_time"] - delta)
		if player["anim_time"] <= 0.0 and player.get("anim_action", "") != "dead":
			player["anim_action"] = "idle"
	var stats: Dictionary = player.get("stats", {})
	if stats.has("regen") and stats["regen"] > 0.0:
		player["hp"] = minf(player.get("max_hp", player["hp"]), player["hp"] + stats["regen"] * delta)
	if player.get("yuan_pulse_cd", 0.0) > 0.0:
		player["yuan_pulse_cd"] = maxf(0.0, player["yuan_pulse_cd"] - delta)
		if player["yuan_pulse_cd"] <= 0.0:
			player["yuan_pulse_cd"] = 10.0
			main._trigger_yuan_pulse()
	elif player.get("yuan_pulse_cd", 0.0) < 10.0:
		player["yuan_pulse_cd"] = minf(player["yuan_pulse_cd"], 10.0)

func movement_dir() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		dir.x += 1.0
	if Input.is_action_pressed("move_up"):
		dir.y -= 1.0
	if Input.is_action_pressed("move_down"):
		dir.y += 1.0
	return dir.normalized()

func move(delta: float):
	if main == null or main.player == null:
		return
	var player: Dictionary = main.player
	if player.get("state", "") == "dead":
		return
	var dir := movement_dir()
	if dir.length_squared() < 0.001:
		if player.get("loop_action", "") != "idle":
			player["loop_action"] = "idle"
			player["loop_clock"] = 0.0
		return
	player["loop_action"] = "run"
	var speed: float = player.get("speed", 230.0) * (1.0 + player.get("stats", {}).get("speed", 0.0))
	if player.get("haste", 0.0) > 0.0:
		speed *= 1.45
	var terrain_speed: float = 1.0
	var new_pos: Vector2 = player.get("pos", Vector2.ZERO) + dir * speed * terrain_speed * delta
	new_pos.x = clampf(new_pos.x, main.ARENA.position.x + player.get("radius", 12.0), main.ARENA.end.x - player.get("radius", 12.0))
	new_pos.y = clampf(new_pos.y, main.ARENA.position.y + player.get("radius", 12.0), main.ARENA.end.y - player.get("radius", 12.0))
	new_pos = main._resolve_pillar_collision(new_pos, player.get("radius", 12.0))
	player["pos"] = new_pos
	player["facing"] = dir.angle()

func attack(aim_pos: Vector2 = Vector2.ZERO, use_aim: bool = false):
	main._attack(aim_pos, use_aim)

func dodge():
	main._dodge()

func use_subskill(aim_pos: Vector2):
	main._use_subskill(aim_pos)

func damage(amount: float):
	main._damage_player(amount)

func trigger_yuan_pulse():
	main._trigger_yuan_pulse()
