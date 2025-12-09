extends Node

signal inventory_changed
signal item_added(item_name: String, quantity: int)
signal item_removed(item_name: String, quantity: int)

var items := {}  

func add_item(item_name: String, quantity: int = 1, icon: Texture2D = null) -> void:
	if items.has(item_name):
		items[item_name]["quantity"] += quantity
	else:
		items[item_name] = {"quantity": quantity, "icon": icon}
	
	emit_signal("item_added", item_name, quantity)
	emit_signal("inventory_changed")
	print("Added ", quantity, "x ", item_name, " to inventory")

func remove_item(item_name: String, quantity: int = 1) -> bool:
	if not has_item(item_name, quantity):
		return false
	
	items[item_name]["quantity"] -= quantity
	if items[item_name]["quantity"] <= 0:
		items.erase(item_name)
	
	emit_signal("item_removed", item_name, quantity)
	emit_signal("inventory_changed")
	return true

func has_item(item_name: String, quantity: int = 1) -> bool:
	if not items.has(item_name):
		return false
	return items[item_name]["quantity"] >= quantity

func get_item_count(item_name: String) -> int:
	if not items.has(item_name):
		return 0
	return items[item_name]["quantity"]

func get_all_items() -> Dictionary:
	return items.duplicate()

func clear() -> void:
	items.clear()
	emit_signal("inventory_changed")
