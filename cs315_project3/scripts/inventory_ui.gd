extends PanelContainer

@onready var item_list: ItemList = $MarginContainer/VBoxContainer/ScrollContainer/ItemList
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

var is_open := false

func _ready():
	visible = false
	
	print("=== INVENTORY UI READY ===")
	print("ItemList exists: ", item_list != null)
	print("Close button exists: ", close_button != null)
	
	if Inventory:
		Inventory.inventory_changed.connect(_update_display)
		print("Connected to Inventory signals")
	else:
		print("ERROR: Inventory autoload not found!")
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	_update_display()

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		toggle()
		get_viewport().set_input_as_handled()

func toggle():
	is_open = !is_open
	visible = is_open
	
	print("Inventory toggled. Open: ", is_open)
	
	if is_open:
		_update_display()

func _update_display():
	print("=== UPDATE DISPLAY CALLED ===")
	
	if not item_list:
		print("ERROR: ItemList not found!")
		return
	
	print("ItemList visible: ", item_list.visible)
	print("ItemList position: ", item_list.position)
	print("ItemList size: ", item_list.size)
	
	item_list.clear()
	var items = Inventory.get_all_items()
	
	print("Items in inventory: ", items)
	print("Number of items: ", items.size())
	
	if items.is_empty():
		print("Adding 'empty' message")
		item_list.add_item("Inventory is empty")
	else:
		for item_name in items.keys():
			var item_data = items[item_name]
			var quantity = item_data["quantity"]
			var icon = item_data.get("icon", null)
			
			var display_text = "%s x%d" % [item_name, quantity]
			print("Adding item to list: ", display_text)
			item_list.add_item(display_text, icon)
	
	print("ItemList now has ", item_list.item_count, " items")

func _on_close_pressed():
	toggle()
