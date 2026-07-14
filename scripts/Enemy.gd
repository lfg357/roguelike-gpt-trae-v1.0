extends RefCounted

var main = null

func _init(main_node):
	main = main_node

func update_combat(delta: float):
	main._update_combat(delta)

func damage(index: int, amount: float, crit: bool, apply_on_hit: bool):
	main._damage_enemy(index, amount, crit, apply_on_hit)

func kill(index: int):
	main._kill_enemy(index)

func spawn(kind: String, pos: Vector2):
	main._spawn_enemy(kind, pos)

func spawn_boss_pillars(phase_two: bool):
	main._spawn_boss_pillars(phase_two)

func clear():
	main.enemies.clear()
	main.boss_pillars.clear()
	main.boss_hazards.clear()
