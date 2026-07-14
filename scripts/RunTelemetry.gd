class_name RunTelemetry
extends RefCounted

var seed := 0
var events: Array[Dictionary] = []


func reset(new_seed: int) -> void:
	seed = new_seed
	events.clear()
	record("run_start", {"seed": seed})


func record(event_name: String, payload := {}) -> void:
	events.append({
		"name": event_name,
		"time_ms": Time.get_ticks_msec(),
		"seed": seed,
		"payload": payload,
	})


func count(event_name: String) -> int:
	var total := 0
	for event in events:
		if event["name"] == event_name:
			total += 1
	return total


func recent(limit: int = 5) -> Array[Dictionary]:
	return events.slice(maxi(0, events.size() - limit), events.size())
