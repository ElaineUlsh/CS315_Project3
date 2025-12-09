extends Control

@onready var instructions_popup = $InstructionsPopup

func _on_how_to_play_button_pressed() -> void:
	instructions_popup.popup_centered()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/rpg.tscn")


func _on_close_button_pressed() -> void:
	instructions_popup.hide()
