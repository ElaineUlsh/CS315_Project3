extends Area2D

@onready var interaction_label = $Label
var player_nearby := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	Controller.must_sleep.connect(_on_must_sleep)
	interaction_label.visible = false

func _process(_delta):
	## if the player is within the bed area and pressed E, they go to sleep
	if player_nearby and Input.is_action_just_pressed("interact"):
		sleep()

func _on_body_entered(body: Node2D):
	## detects when the player has entered the bed area
	if body.name == "Player":
		player_nearby = true
		update_label()

func _on_body_exited(body: Node2D):
	## detects when the player has left the bed area
	if body.name == "Player":
		player_nearby = false
		interaction_label.visible = false

func _on_must_sleep():
	## plays when the play is out of energy
	interaction_label.text = "You must sleep! (Press E)"
	interaction_label.modulate = Color.RED

func update_label():
	## hovers the labels above the bed so that the player knows what to do when they're near it
	if Controller.energy <= 0:
		interaction_label.text = "You must sleep! (Press E)"
		interaction_label.modulate = Color.RED
	else:
		interaction_label.text = "Press E to sleep"
		interaction_label.modulate = Color.WHITE
	interaction_label.visible = true

func sleep():
	## calls the sleep function in the controller after fading to black
	AudioManager.go_to_sleep_or_plant_crop()
	get_tree().paused = true
	await get_tree().create_timer(1.0).timeout
	Controller.sleep()
	get_tree().paused = false
