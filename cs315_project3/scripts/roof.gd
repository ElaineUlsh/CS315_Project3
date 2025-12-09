extends Area2D

@onready var roof_layer: TileMapLayer = get_parent()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		roof_layer.visible = false

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		roof_layer.visible = true
