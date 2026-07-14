extends RefCounted

var main = null

func _init(main_node):
	main = main_node

func generate_map():
	main._generate_map()

func enter_room(index: int):
	main._enter_room(index)

func spawn_room(room_type: String):
	main._spawn_room(room_type)

func clear_room():
	main._clear_room()

func available_exit_links(room_index: int) -> Array[int]:
	return main._available_exit_links(room_index)

func visible_exit_links(room_index: int) -> Array[int]:
	return main._visible_exit_links(room_index)

func nearest_exit_room() -> int:
	return main._nearest_exit_room()

func exit_rect_for_link(from_idx: int, to_idx: int) -> Rect2:
	return main._exit_rect_for_link(from_idx, to_idx)

func next_floor():
	main.current_floor += 1
	main._generate_map()
	main._enter_room(0)
