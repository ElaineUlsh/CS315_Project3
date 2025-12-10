extends PanelContainer

@onready var speaker_label: Label = $MarginContainer/VBoxContainer/SpeakerLabel
@onready var dialogue_label: Label = $MarginContainer/VBoxContainer/DialogueLabel
@onready var continue_button: Button = $MarginContainer/VBoxContainer/ContinueButton

var dialogue_queue: Array[Dictionary] = []
var is_showing: bool = false
var is_ocd_message: bool = false

signal dialogue_finished

func _ready():
	add_to_group("dialogue_box")
	visible = false
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

func _input(event: InputEvent) -> void:
	if is_showing and event.is_action_pressed("interact"):
		_on_continue_pressed()
		get_viewport().set_input_as_handled()

func show_dialogue(speaker: String, text: String):
	dialogue_queue.clear()
	dialogue_queue.append({"speaker": speaker, "text": text})
	_display_next()

func show_dialogue_sequence(messages: Array[Dictionary]):
	dialogue_queue = messages.duplicate()
	_display_next()

func _display_next():
	if dialogue_queue.is_empty():
		_close()
		return
	
	var message = dialogue_queue.pop_front()
	
	if speaker_label:
		speaker_label.text = message.get("speaker", "")
		speaker_label.visible = message.get("speaker", "") != ""
	
	if dialogue_label:
		dialogue_label.text = message.get("text", "")
	if continue_button:
		continue_button.visible = true
	visible = true
	is_showing = true

func _on_continue_pressed():
	_display_next()

func _close():
	visible = false
	is_showing = false
	emit_signal("dialogue_finished")
	
## the following code is just for the OCD interactions
func show_message(text: String):
	is_ocd_message = true
	dialogue_queue.clear()
	
	if speaker_label:
		speaker_label.visible = false
		
	if dialogue_label:
		dialogue_label.text = text
		
	continue_button.visible = false
	visible = true
	is_showing = true
	
func update_countdown(time_left: float):
	if is_ocd_message and dialogue_label:
		dialogue_label.text = "⚠ OCD Event!\nTime left: " + str(time_left)

func hide_message():
	if is_ocd_message:
		visible = false
		is_showing = false
		is_ocd_message = false
		continue_button.visible = true
		emit_signal("dialogue_finished")
