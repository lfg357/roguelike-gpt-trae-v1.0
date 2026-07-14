extends RefCounted

var main = null

func _init(main_node):
	main = main_node

func setup(relics_data: Array, initial_inventory: Array):
	main.relics = relics_data
	main.player["inventory"] = initial_inventory

func get_all_relics() -> Array:
	return main.relics

func get_inventory() -> Array:
	return main.player["inventory"]

func add_to_inventory(relic: Dictionary):
	if main.player["inventory"].size() < 8:
		main.player["inventory"].append(relic)

func remove_from_inventory(index: int):
	if index >= 0 and index < main.player["inventory"].size():
		main.player["inventory"].remove_at(index)

func random_relic() -> Dictionary:
	return main._random_relic()

func buy_price(item: Dictionary) -> int:
	return main._relic_buy_price(item)

func sell_price(item: Dictionary) -> int:
	return main._relic_sell_price(item)
