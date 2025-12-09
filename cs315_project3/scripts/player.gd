extends CharacterBody2D

var speed = 60
var facing = "front" 
var is_moving : bool = false
var is_attacking : bool = false
var is_watering: bool = false

@onready var animated_sprite = $AnimatedSprite2D

var crop_scene = preload("res://scenes/crop.tscn")
@export var ground_tilemap_path: NodePath
var ground_tilemap: TileMapLayer
var interact_search_radius: float = 160.0
var selected_seed: String = "Corn Seed"
var selected_crop_scene: PackedScene = preload("res://scenes/crop.tscn")

func _ready():
	print("=== PLAYER READY ===")
	Inventory.add_item("Corn Seed", 10)
	print("Inventory items: ", Inventory.get_all_items())
	print("Has 5 seeds?: ", Inventory.has_item("Corn Seed", 5))
	is_watering = false
	if ground_tilemap_path != null:
		ground_tilemap = get_node(ground_tilemap_path)

func _unhandled_input(event: InputEvent) -> void:
	# Handle mouse clicks for OCD objects
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(event.position)

func _handle_click(_screen_position: Vector2) -> void:
	# Check if there's an active interactable (OCD object)
	if Controller.active_interactable == null:
		return
	
	if not Controller.active_interactable.has_method("on_click"):
		return
	
	# Try to click on it
	var success = Controller.active_interactable.on_click(self)
	
	if success:
		print("Successfully clicked OCD object!")
	else:
		print("Click failed - too far or invalid")

func _physics_process(_delta: float) -> void:
	var dir = Input.get_vector("left", "right", "up", "down")
	
	# Block movement while watering
	if is_watering:
		velocity = Vector2.ZERO
		return
	
	self.velocity = dir * speed

	if Input.is_action_pressed("left"):
		is_moving = true
		facing = "left"
	elif Input.is_action_pressed("right"):
		is_moving = true
		facing = "right"
	elif Input.is_action_pressed("up"):
		is_moving = true
		facing = "back"
	elif Input.is_action_pressed("down"):
		is_moving = true
		facing = "front"
	else:
		velocity = Vector2.ZERO
		is_moving = false
	
	if Input.is_action_just_pressed("water"):
		AudioManager.water_or_harvest()
		start_watering()
		return
	
	if Input.is_action_just_pressed("interact"):
		AudioManager.interact()
		_try_interact()
		
	if Input.is_action_just_pressed("plant"):
		AudioManager.go_to_sleep_or_plant_crop()
		try_plant_seed()

	if Input.is_action_just_pressed("harvest"):
		AudioManager.water_or_harvest()
		try_harvest_crop()
	
	if is_moving == true:
		var anim_string = "walk_" + facing
		animated_sprite.play(anim_string)
	elif is_moving == false:
		var anim_string = "idle_" + facing
		animated_sprite.play(anim_string)
	
	move_and_slide()

func start_watering():
	if not Controller.consume_energy_for_action("water"):
		DialogueManager.show_message("System", "Not enough energy to water!")
		return
	
	is_watering = true
	animated_sprite.play("water_" + facing)
	water_facing_tile()
	
	await animated_sprite.animation_finished
	
	is_watering = false

func water_facing_tile():
	if ground_tilemap == null:
		push_warning("Player has no TileMap assigned for watering :'(")
		return
		
	var direction = {
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT,
		"back": Vector2.UP,
		"front": Vector2.DOWN
	}[facing]
	
	var target_world_position = global_position + direction * 16
	var tile_position = ground_tilemap.local_to_map(target_world_position)
	
	if ground_tilemap.is_tile_waterable(tile_position):
		ground_tilemap.water(tile_position)

func _try_interact() -> void:
	if DialogueManager.dialogue_box and DialogueManager.dialogue_box.is_showing:
		return
	
	if not Controller.consume_energy_for_action("interact"):
		DialogueManager.show_message("System", "Not enough energy!")
		return
		
	var space = get_tree().get_nodes_in_group("interactables")
	var closest = null
	var closest_distance = INF
	
	for node in space:
		if not node is Node2D:
			continue
		var distance = global_position.distance_to(node.global_position)
		if distance <= interact_search_radius:
			# Check if it's an OCD object that's glowing
			if node.has_method("try_activate") and node.glowing:
				if distance < closest_distance:
					closest = node
					closest_distance = distance
			# Check if it's an NPC
			elif node.has_method("interact"):
				if distance < closest_distance:
					closest = node
					closest_distance = distance
	
	if closest:
		if closest.has_method("try_activate"):
			# It's an OCD object
			var is_active = closest.try_activate(self)
			if is_active:
				print("Activated OCD interaction with ", closest.name)
			else:
				print("Could not activate ", closest.name)
		elif closest.has_method("interact"):
			# It's an NPC
			closest.interact()
			print("Interacting with NPC: ", closest.name)
	else:
		pass

func try_plant_seed():
	if not Controller.consume_energy_for_action("plant"):
		DialogueManager.show_message("System", "Not enough energy to plant!")
		return 
		
	if not Inventory.has_item(selected_seed, 1):
		DialogueManager.show_message("System", "No seeds to plant!")
		return
	
	if ground_tilemap == null:
		return
	
	var direction = {
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT,
		"back": Vector2.UP,
		"front": Vector2.DOWN
	}[facing]
	
	var target_world_position = global_position + direction * 16
	var tile_position = ground_tilemap.local_to_map(target_world_position)
	
	if not ground_tilemap.is_tile_waterable(tile_position):
		DialogueManager.show_message("System", "Cannot plant here!")
		return
	
	# Check if there's already a crop here
	var crops = get_tree().get_nodes_in_group("crops")
	for crop in crops:
		if crop.tile_position == tile_position:
			DialogueManager.show_message("System", "Already a crop here!")
			return
	
	plant_crop_at(tile_position)
	Inventory.remove_item(selected_seed, 1)
	
	for quest_id in QuestManager.active_quests.keys():
		var quest = QuestManager.active_quests[quest_id]
		if quest.type == "plant":
			QuestManager.update_quest_progress(quest_id, 1)
	
	print("Planted ", selected_seed)

func plant_crop_at(tile_position: Vector2i):
	var crop = selected_crop_scene.instantiate()
	crop.position = ground_tilemap.map_to_local(tile_position)

	if crop.has_method("set_tilemap"):
		crop.set_tilemap(ground_tilemap)

	crop.add_to_group("crops")
	get_parent().add_child(crop)
	print("Planted crop at: ", tile_position)

func try_harvest_crop():
	if not Controller.consume_energy_for_action("harvest"):
		DialogueManager.show_message("System", "Not enough energy to harvest!")
		return
		
	var crops = get_tree().get_nodes_in_group("crops")
	var nearest_crop = null
	var nearest_distance = 32.0 
	
	for crop in crops:
		if not crop.has_method("harvest"):
			continue
		if not crop.is_harvestable:
			continue
			
		var distance = global_position.distance_to(crop.global_position)
		if distance < nearest_distance:
			nearest_crop = crop
			nearest_distance = distance
	
	if nearest_crop:
		var crop_type = nearest_crop.crop_type
		var yield_amount = nearest_crop.harvest_yield
		
		if nearest_crop.harvest(self):
			for quest_id in QuestManager.active_quests.keys():
				var quest = QuestManager.active_quests[quest_id]
				if quest.type == "harvest" and quest.target_item == crop_type:
					QuestManager.update_quest_progress(quest_id, yield_amount)
			
			DialogueManager.show_message("System", "Harvested " + str(yield_amount) + "x " + crop_type + "!")
	else:
		DialogueManager.show_message("System", "No crops nearby to harvest!")
