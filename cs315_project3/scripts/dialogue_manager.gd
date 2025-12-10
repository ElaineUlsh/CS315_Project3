## made with the help of ai, because this was really confusing to me
extends Node

var dialogue_box: Node = null
var waiting_for_end_game: bool = false

signal dialogue_closed

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	dialogue_box = _find_dialogue_box()
	
	if dialogue_box:
		print("DialogueManager found DialogueBox")
		if dialogue_box.has_signal("dialogue_finished"):
			dialogue_box.dialogue_finished.connect(_on_dialogue_box_closed)
	else:
		push_warning("DialogueManager could not find DialogueBox in scene!")

func _on_dialogue_box_closed():
	emit_signal("dialogue_closed")
	
	if waiting_for_end_game:
		waiting_for_end_game = false
		print("End game dialogue closed, changing to title screen...")
		await get_tree().process_frame
		get_tree().change_scene_to_file("res://scenes/title.tscn")

func _find_dialogue_box() -> Node:
	var nodes = get_tree().get_nodes_in_group("dialogue_box")
	if nodes.size() > 0:
		return nodes[0]
	var root = get_tree().root
	return _search_for_dialogue_box(root)

func _search_for_dialogue_box(node: Node) -> Node:
	if node.has_method("show_dialogue") and node.has_method("show_message"):
		return node
	
	for child in node.get_children():
		var result = _search_for_dialogue_box(child)
		if result:
			return result
	
	return null

func show_message(speaker: String, text: String):
	if dialogue_box == null:
		dialogue_box = _find_dialogue_box()
	if dialogue_box and dialogue_box.has_method("show_dialogue"):
		dialogue_box.show_dialogue(speaker, text)
	else:
		print("[DIALOGUE] ", speaker, ": ", text)

func show_conversation(messages: Array[Dictionary]):
	if dialogue_box == null:
		dialogue_box = _find_dialogue_box()
	if dialogue_box and dialogue_box.has_method("show_dialogue_sequence"):
		dialogue_box.show_dialogue_sequence(messages)
	else:
		for msg in messages:
			print("[DIALOGUE] ", msg.get("speaker", ""), ": ", msg.get("text", ""))

func end_of_game():
	if dialogue_box == null:
		dialogue_box = _find_dialogue_box()
	
	if dialogue_box:
		waiting_for_end_game = true
		show_message("System", "YOU HAVE OCD!")
		await dialogue_closed
	else:
		await get_tree().create_timer(2.0).timeout
	
	get_tree().change_scene_to_file("res://scenes/title.tscn")
