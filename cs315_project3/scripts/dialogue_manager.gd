## made with the help of ai, because this was really confusing to me
extends Node

var dialogue_box: Node = null

signal dialogue_closed

func _ready():
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

func _find_dialogue_box() -> Node:
	var nodes = get_tree().get_nodes_in_group("dialogue_box")
	if nodes.size() > 0:
		return nodes[0]
	return null

func show_message(speaker: String, text: String):
	print(dialogue_box)
	print(dialogue_box.has_method("show_dialogue"))
	if dialogue_box and dialogue_box.has_method("show_dialogue"):
		dialogue_box.show_dialogue(speaker, text)
	else:
		print("[DIALOGUE] ", speaker, ": ", text)

func show_conversation(messages: Array[Dictionary]):
	if dialogue_box and dialogue_box.has_method("show_dialogue_sequence"):
		dialogue_box.show_dialogue_sequence(messages)
	else:
		for msg in messages:
			print("[DIALOGUE] ", msg.get("speaker", ""), ": ", msg.get("text", ""))
