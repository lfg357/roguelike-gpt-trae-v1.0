extends RefCounted

var main = null

func _init(main_node):
	main = main_node

# --- 信号回调 ---
func _on_disk_changed(disk: Array):
	if disk.size() != 5:
		push_warning("disk_changed received disk with size %d, expected 5" % disk.size())

func setup(initial_disk: Array):
	if main == null or main.player == null:
		return
	main.player["disk"] = initial_disk

func get_disk() -> Array:
	if main == null or main.player == null:
		return []
	return main.player["disk"]

func get_patterns() -> Array:
	if main == null or main.player == null:
		return []
	return main.player["patterns"]

func get_combos() -> Array:
	if main == null or main.player == null:
		return []
	return main.player["combos"]

func get_element_counts() -> Dictionary:
	if main == null or main.player == null:
		return {}
	return main.player["element_counts"]

func set_disk(new_disk: Array):
	if main == null or main.player == null:
		return
	main.player["disk"] = new_disk
	main._evaluate_build()

func place_relic(relic: Dictionary, slot: int):
	if main == null or main.player == null:
		return
	if slot >= 0 and slot < main.player["disk"].size():
		main.player["disk"][slot] = relic
		main._evaluate_build()

func remove_relic(slot: int):
	if main == null or main.player == null:
		return
	if slot >= 0 and slot < main.player["disk"].size():
		main.player["disk"][slot] = null
		main._evaluate_build()

func swap_relics(slot1: int, slot2: int):
	if main == null or main.player == null:
		return
	if slot1 >= 0 and slot1 < main.player["disk"].size() and slot2 >= 0 and slot2 < main.player["disk"].size():
		var temp: Variant = main.player["disk"][slot1]
		main.player["disk"][slot1] = main.player["disk"][slot2]
		main.player["disk"][slot2] = temp
		main._evaluate_build()

func replace_relic(slot: int, new_relic: Dictionary) -> Dictionary:
	if main == null or main.player == null:
		return {}
	if slot < 0 or slot >= main.player["disk"].size():
		return {}
	var old_relic = main.player["disk"][slot]
	if old_relic == null:
		old_relic = {}
	main.player["disk"][slot] = new_relic
	main._evaluate_build()
	return old_relic

func has_empty_slot() -> bool:
	if main == null or main.player == null:
		return false
	for item in main.player["disk"]:
		if item == null:
			return true
	return false

func get_empty_slot() -> int:
	if main == null or main.player == null:
		return -1
	for i in range(main.player["disk"].size()):
		if main.player["disk"][i] == null:
			return i
	return -1

func is_full() -> bool:
	return not has_empty_slot()

func evaluate():
	if main == null:
		return
	main._evaluate_build()

func preview_placement(relic: Dictionary, slot: int) -> Dictionary:
	if main == null or main.player == null:
		return {"patterns": [], "combos": [], "stats": {}, "element_counts": {}}
	if slot < 0 or slot >= main.player["disk"].size():
		return {"patterns": [], "combos": [], "stats": {}, "element_counts": {}}
	var preview_disk: Array = main.player["disk"].duplicate()
	preview_disk[slot] = relic
	var active_relics := []
	for r in preview_disk:
		if r != null:
			active_relics.append(r)
	if active_relics.is_empty():
		return {"patterns": [], "combos": [], "stats": {}, "element_counts": {}}
	var RULES = preload("res://scripts/FiveElementRules.gd")
	var rules := RULES.new()
	return rules.evaluate(active_relics)

func clear():
	if main == null or main.player == null:
		return
	main.player["disk"] = [null, null, null, null, null]
	main._evaluate_build()
