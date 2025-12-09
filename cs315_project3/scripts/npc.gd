extends CharacterBody2D

@export var npc_name: String = "Farmer Joe"
@export var dialogue_lines: Array[String] = ["Hello there!", "How can I help?"]
@export var quest_id: String = ""
@export var is_quest_giver: bool = false
@export var is_quest_target: bool = false

@export var movement_speed: float = 30.0
@export var idle_time_min: float = 2.0
@export var idle_time_max: float = 5.0
@export var walk_time_min: float = 1.0
@export var walk_time_max: float = 3.0
@export var wander_radius: float = 100.0

@onready var interaction_area: Area2D = $InteractionArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var name_label: Label = $NameLabel
@onready var state_timer: Timer = $StateTimer

enum State { IDLE, WALKING, TALKING }
var current_state: State = State.IDLE
var facing_direction: String = "front"
var is_facing_left: bool = false
var home_position: Vector2
var target_position: Vector2
var player_nearby: bool = false
var player_reference: Node2D = null
var current_dialogue_index: int = 0

func _ready():
	add_to_group("interactables")
	home_position = global_position

	DialogueManager.dialogue_closed.connect(_on_dialogue_closed)

	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	if name_label:
		name_label.text = npc_name

	if not state_timer:
		state_timer = Timer.new()
		add_child(state_timer)
	state_timer.timeout.connect(_on_state_timer_timeout)

	_start_idle_state()

func _physics_process(_delta):
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			_update_animation("idle")

		State.WALKING:
			_handle_walking()

		State.TALKING:
			velocity = Vector2.ZERO
			_face_player()
			_update_animation("idle")

	move_and_slide()

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact") and current_state != State.TALKING:
		interact()

func _start_idle_state():
	current_state = State.IDLE
	velocity = Vector2.ZERO
	state_timer.start(randf_range(idle_time_min, idle_time_max))

func _start_walking_state():
	current_state = State.WALKING
	var angle = randf() * TAU
	var distance = randf() * wander_radius
	target_position = home_position + Vector2(cos(angle), sin(angle)) * distance
	state_timer.start(randf_range(walk_time_min, walk_time_max))

func _start_talking_state():
	current_state = State.TALKING
	velocity = Vector2.ZERO

func _end_talking_state():
	if current_state == State.TALKING:
		_start_idle_state()


func _on_state_timer_timeout():
	if current_state == State.TALKING:
		return

	if current_state == State.IDLE:
		if randf() > 0.3:
			_start_walking_state()
		else:
			_start_idle_state()
	elif current_state == State.WALKING:
		_start_idle_state()

func _handle_walking():
	var direction = (target_position - global_position).normalized()

	if global_position.distance_to(target_position) < 5.0:
		_start_idle_state()
		return

	velocity = direction * movement_speed
	_update_facing_from_velocity(direction)
	_update_animation("walk")

func _update_facing_from_velocity(direction):
	var abs_x = abs(direction.x)
	var abs_y = abs(direction.y)

	if abs_y > abs_x:
		if direction.y < 0:
			facing_direction = "back"
			is_facing_left = false
		else:
			facing_direction = "front"
			is_facing_left = false
	else:
		facing_direction = "side"
		is_facing_left = direction.x < 0

func _face_player():
	if not player_reference:
		return
	var direction = (player_reference.global_position - global_position).normalized()
	_update_facing_from_velocity(direction)

func _update_animation(state_suffix):
	if not animated_sprite:
		return

	var anim_name = facing_direction + "_" + state_suffix

	if facing_direction == "side":
		animated_sprite.flip_h = is_facing_left
	else:
		animated_sprite.flip_h = false

	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		player_reference = body

func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false
		player_reference = null
		if current_state == State.TALKING:
			_end_talking_state()

func interact():
	if current_state == State.TALKING:
		return
	_start_talking_state()

	if DialogueManager.dialogue_box == null:
		await get_tree().process_frame

	if is_quest_target:
		check_quest_delivery()
		return

	if is_quest_giver and quest_id != "":
		if not QuestManager.is_quest_completed(quest_id):
			if not QuestManager.is_quest_active(quest_id):
				offer_quest()
				return
			else:
				check_quest_completion()
				return
	
	print("Interacting with NPC: ", npc_name)
	print("Current state: ", current_state)
	print("DialogueManager ready: ", DialogueManager.dialogue_box != null)

	show_dialogue()

func show_dialogue():
	if dialogue_lines.is_empty():
		return

	var line = dialogue_lines[current_dialogue_index]
	DialogueManager.show_message(npc_name, line)

	current_dialogue_index = (current_dialogue_index + 1) % dialogue_lines.size()

func offer_quest():
	var quest = create_quest_for_id(quest_id)
	if quest:
		QuestManager.accept_quest(quest)
		DialogueManager.show_message(npc_name, quest.description)


func check_quest_completion():
	var quest = QuestManager.get_quest(quest_id)

	if quest and quest.current_progress >= quest.goal:
		QuestManager.complete_quest(quest_id)
		DialogueManager.show_message(npc_name, quest.description)
	else:
		DialogueManager.show_message(npc_name, "You're not done yet!")


func check_quest_delivery():
	for qid in QuestManager.active_quests.keys():
		var quest = QuestManager.active_quests[qid]

		if quest.type == "deliver" and quest.target_npc == npc_name:
			if Inventory.has_item(quest.target_item, quest.goal):
				Inventory.remove_item(quest.target_item, quest.goal)
				QuestManager.complete_quest(qid)
				DialogueManager.show_message(npc_name, "Thanks for the delivery!")
				return

	show_dialogue()


func create_quest_for_id(qid: String) -> QuestManager.Quest:
	var quest = QuestManager.Quest.new(qid, "Example Quest", "Do a thing")

	match qid:
		"plant_corn":
			quest.title = "Plant Some Corn"
			quest.description = "Plant 5 corn plants in the garden"
			quest.type = "plant"
			quest.goal = 5
			quest.target_item = "Corn"
			quest.reward_items = {"Gold": 50, "Corn Seed": 10}
		"harvest_crops":
			quest.title = "Harvest Crops"
			quest.description = "Harvest 10 corn for me"
			quest.type = "harvest"
			quest.goal = 10
			quest.target_item = "Corn"
			quest.reward_items = {"Gold": 100}
		"talk_to_mayor":
			quest.title = "Speak to the Mayor"
			quest.description = "Go talk to Mayor Smith in the town square"
			quest.type = "talk"
			quest.goal = 1
			quest.target_npc = "Mayor Smith"
			quest.reward_items = {"Gold": 25}
		"deliver_corn":
			quest.title = "Deliver Corn"
			quest.description = "Bring 5 corn to Chef Mario at the restaurant"
			quest.type = "deliver"
			quest.goal = 5
			quest.target_npc = "Chef Mario"
			quest.target_item = "Corn"
			quest.reward_items = {"Gold": 150, "Corn Seed": 5}

	return quest

func _on_dialogue_closed():
	if current_state == State.TALKING:
		_end_talking_state()
