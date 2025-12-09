extends Node

@export_range(0, 100, 1) var max_energy: int = 100
var energy: int = max_energy
var active_interactable: Node = null
var has_shown_sleep_warning: bool = false

@export var energy_drain_per_second: float = 0.5
@export var action_energy_costs := {
	"water": 2,
	"plant": 3,
	"harvest": 2,
	"interact": 5
}

@export var day_length_seconds: float = 300.0  # 5 minutes per day
var current_time: float = 0.0  # 0 = midnight, 0.5 = noon, 1.0 = midnight
var current_day: int = 1
var is_night_time: bool = false

signal energy_changed(new_energy: int)
signal day_changed(new_day: int)
signal time_changed(time: float)
signal must_sleep
signal new_day_started

## sets the energy to highest energy setting upon loading the game
func _ready() -> void:
	energy = max_energy
	
func _process(delta: float) -> void:
	## increments the current time
	current_time += delta / day_length_seconds
	
	if current_time >= 1.0:
		current_time = 0.0
		current_day += 1 ## if after midnight, it is a new day
		emit_signal("day_changed", current_day)
		emit_signal("new_day_started")
		
	is_night_time = current_time < 0.25 or current_time > 0.75
	
	emit_signal("time_changed", current_time)
	
	if not is_night_time:
		apply_energy_loss(int(energy_drain_per_second * delta))

## energy is lost with interactions, harvesting, watering, planting... really anything the player does
func apply_energy_loss(amount: int) -> void:
	var old_energy = energy
	energy = maxi(0, energy - amount)
	
	if energy != old_energy:
		emit_signal("energy_changed", energy)
	
	if energy <= 0:
		has_shown_sleep_warning = true
		emit_signal("must_sleep")
		DialogueManager.show_message("System", "You're exhausted! Find your bed and sleep!")
	
## this returns whether or not the action consumes energy, should almost always return true
func consume_energy_for_action(action: String) -> bool:
	if not action_energy_costs.has(action):
		return true
		
	var cost = action_energy_costs[action]
	if energy < cost:
		return false
		
	apply_energy_loss(cost) ## if it does consume energy, it consumes the energy
	return true

## player sleeps
func sleep() -> void:
	current_day += 1
	energy = max_energy
	emit_signal("energy_changed", energy)
	emit_signal("day_changed", current_day)
	emit_signal("new_day_started")
	current_time = 0.25
	emit_signal("time_changed", current_time)
	
	is_night_time = false
	has_shown_sleep_warning = false
	
	DialogueManager.show_message("System", "Good morning! Day " + str(current_day)) ## dialogue to show a new day starting

## if the player is interacting with an object, this stores the value of that object
func set_active_interactable(node: Node) -> void:
	active_interactable = node
	
## gets rid of it when the player is no longer interacting with the object
func clear_active_interactable(node: Node) -> void:
	if active_interactable == node:
		active_interactable = null

## loops the music -- didn't let me do it in the inspector for some reason
func _on_audio_stream_player_finished() -> void:
	AudioManager.play_sound(AudioManager.game_play_sound)
