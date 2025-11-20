extends CharacterBody2D

var speed = 60
var facing = "front" ## Stores last facing of the character
var is_moving : bool = false
var is_attacking : bool = false
@onready var animated_sprite = $AnimatedSprite2D

#@export var max_health: int = 20
#var current_health: int = max_health
#@onready var health_bar = $Camera2D/PlayerView/HealthBar

#func _ready() -> void:
	#current_health = max_health

func _process(_delta: float) -> void:
	var dir = Input.get_vector("left", "right", "up", "down")
	self.velocity = dir * speed
	
	## setting up for the animation change
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
	
	## change animations
	if is_moving == true:
		var anim_string = "walk_" + facing
		animated_sprite.play(anim_string)
	elif is_moving == false: ## and animated_sprite.current_animation != "punch":
		var anim_string = "idle_" + facing
		animated_sprite.play(anim_string)
	
	move_and_slide()
