extends RigidBody2D

@export var glow_interval : float = 45.0
@export var glow_on_duration : float = 3.0
@export var interaction_duration : float = 30.0
@export var active_distance : float = 128.0
@export var click_distance : float = 96.0
@export var energy_penalty : int = 10

@onready var sprite : Sprite2D = $Sprite
@onready var outline: Sprite2D = $Outline
@onready var dialogue_box = get_tree().get_first_node_in_group("dialogue_box")

var glow_timer: Timer
var interaction_timer: Timer
var countdown_label: Label

var glowing := false
var active := false
var activating_player: Node2D = null


func _ready():
	add_to_group("interactables")
	outline.visible = false

	# Initialize timers
	glow_timer = _ensure_timer("GlowTimer")
	interaction_timer = _ensure_timer("InteractionTimer")

	# Countdown label
	countdown_label = _ensure_label()
	countdown_label.visible = false

	# Glow timer setup
	glow_timer.wait_time = glow_interval
	glow_timer.one_shot = false
	glow_timer.start()
	glow_timer.timeout.connect(_on_glow_timer_timeout)

	# Interaction timer setup
	interaction_timer.one_shot = true
	interaction_timer.wait_time = interaction_duration
	interaction_timer.timeout.connect(_on_interaction_timeout)

	await get_tree().create_timer(randf() * glow_interval).timeout
	_toggle_glow(true)
	await get_tree().create_timer(glow_on_duration).timeout
	_toggle_glow(false)


func _process(_delta):
	if active and interaction_timer.time_left > 0:
		var t = snapped(interaction_timer.time_left, 0.1)
		countdown_label.visible = true
		countdown_label.text = str(t)

		if dialogue_box:
			dialogue_box.update_countdown(t)
	else:
		countdown_label.visible = false


func _ensure_timer(node_name: String) -> Timer:
	if has_node(node_name):
		return get_node(node_name)
	var t := Timer.new()
	t.name = node_name
	add_child(t)
	return t

func _ensure_label() -> Label:
	if has_node("CountdownLabel"):
		return get_node("CountdownLabel")
	var lbl := Label.new()
	lbl.name = "CountdownLabel"
	add_child(lbl)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-20, -40)
	lbl.add_theme_font_size_override("font_size", 20)
	return lbl

func _on_glow_timer_timeout():
	_toggle_glow(true)
	var t = get_tree().create_timer(glow_on_duration)
	t.timeout.connect(Callable(self, "_toggle_glow").bind(false))


func _toggle_glow(on: bool) -> void:
	glowing = on
	outline.visible = on

	if on:
		if dialogue_box:
			dialogue_box.show_message("⚠ An intrusive thought needs attention!")

		_begin_auto_interaction()
	else:
		if dialogue_box:
			dialogue_box.hide_message()


func _begin_auto_interaction():
	if active:
		return  # already in progress

	AudioManager.ocd_event()
	active = true
	activating_player = null  # auto-start means any player can finish
	interaction_timer.start(interaction_duration)

	Controller.set_active_interactable(self)

	if dialogue_box:
		dialogue_box.update_countdown(interaction_duration)

func try_activate(player_node: Node2D) -> bool:
	if not glowing:
		return false
	if active: # already active (auto started)
		activating_player = player_node
		return true

	active = true
	activating_player = player_node
	interaction_timer.start(interaction_duration)

	Controller.set_active_interactable(self)
	outline.visible = true

	return true

func on_click(player_node: Node2D) -> bool:
	if not active:
		return false

	if activating_player and activating_player != player_node:
		return false

	if global_position.distance_to(player_node.global_position) > click_distance:
		return false

	_succeed()
	return true

func _on_interaction_timeout():
	if not active:
		return
	_fail()


func _succeed():
	if not active:
		return

	if interaction_timer and !interaction_timer.is_stopped():
		interaction_timer.stop()

	AudioManager.ocd_success()
	active = false
	activating_player = null

	Controller.clear_active_interactable(self)

	if dialogue_box:
		dialogue_box.hide_message()

	_toggle_glow(false)


func _fail():
	AudioManager.ocd_event()
	active = false
	activating_player = null

	Controller.clear_active_interactable(self)

	if dialogue_box:
		dialogue_box.show_message("✗ You lost energy to an intrusive thought...")
		await get_tree().create_timer(1.8).timeout
		dialogue_box.hide_message()

	Controller.apply_energy_loss(energy_penalty)
	_toggle_glow(false)
