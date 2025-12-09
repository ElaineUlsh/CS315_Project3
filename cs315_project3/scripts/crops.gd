extends Node2D

@export var growth_time = 30.0
@export var watered_growth_multiplier = 2.0
@export var crop_type: String = "Corn" 
@export var harvest_yield: int = 3  # How many items you get
@export var tilemap_path: NodePath = "/root/Main/Garden"

@export var frame_size: Vector2i = Vector2i(16, 16)
@onready var sprite: Sprite2D = $Sprite2D

var tilemap : TileMapLayer
var tile_position: Vector2i
var growth: float = 0.0
var is_mature: bool = false
var is_harvestable: bool = false
var _tried_find_tilemap: bool = false

func _ready() -> void:
	growth = 0.0
	is_mature = false
	is_harvestable = false
	
	if sprite:
		_set_region_frame(1)
	
	await get_tree().process_frame
	
	if tilemap_path != NodePath(""):
		var tm = get_node_or_null(tilemap_path)
		if tm == null and str(tilemap_path).begins_with("/"):
			tm = get_tree().get_root().get_node_or_null(tilemap_path)
		tilemap = tm
	
	if tilemap == null:
		tilemap = _find_tilemap()
	
	if tilemap == null:
		push_error("Crop cannot find tilemap!")
		queue_free()
		return
	
	tile_position = tilemap.local_to_map(global_position)
	print("Crop create at tile position: ", tile_position)
	update_visual()
	
func _find_tilemap() -> TileMapLayer:
	var root = get_tree().root
	var garden = _find_node_by_name(root, "Garden")
	if garden:
		print("Found Garden tilemap!")
		return garden
			
	return null

func _find_node_by_name(node: Node, target_name: String) -> TileMapLayer:
	if node.name == target_name and node is TileMapLayer:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_name(child, target_name)
		if result:
			return result
	
	return null

func set_tilemap(tm: TileMapLayer) -> void:
	tilemap = tm
	if tilemap:
		tile_position = tilemap.local_to_map(global_position)
		print("Tilemap set for crop at: ", tile_position)

func _process(delta: float) -> void:
	if is_mature:
		return
	
	## if the tilemap is null, it tries to get it again
	if tilemap == null:
		if not _tried_find_tilemap:
			tilemap = _find_tilemap()
			_tried_find_tilemap = true
			if tilemap:
				tile_position = tilemap.local_to_map(global_position)
				print("Found tilemap late, crop tile: ", tile_position)
		if tilemap == null:
			return
	
	## checks whether the tile is wet at that specific position
	var is_wet = tilemap.is_tile_wet(tile_position)
	
	## if it's wet, it grows a LOT faster
	if is_wet:
		growth += (delta / growth_time) * watered_growth_multiplier
	else:
		growth += delta / growth_time
		
	growth = clamp(growth, 0.0, 1.0) ## the plant can only grow so much
	
	## indicates whether the plant is ready for harvest yet
	if growth >= 1.0 and not is_mature:
		is_mature = true
		is_harvestable = true
		print(crop_type, " is ready to harvest!")
	
	update_visual()

## sets which region of the atlas texture you're currently seeing
func _set_region_frame(index: int) -> void:
	if not sprite or sprite.texture == null:
		return
		
	var region = Rect2(
		Vector2(index * frame_size.x, 0), 
		frame_size
	)
	
	sprite.region_enabled = true
	sprite.region_rect = region

## update the region of the atlas texture to be of the new phase of growth of the crop
func update_visual():
	if not sprite:
		return
		
	var index = 1
	
	# 0: seed, 1: sprout, 2: small, 3: mature
	if growth < 0.25:
		index = 1
	elif growth < 0.5:
		index = 2
	elif growth < 0.75:
		index = 3
	else:
		index = 4
		if is_mature:
			sprite.modulate = Color(1, 1, 1, 1)  # Full brightness when mature
	
	_set_region_frame(index)

## when you harvest the crop, it goes into your inventory
func harvest(_player: Node2D) -> bool:
	if not is_harvestable:
		return false
	_set_region_frame(0)
	var crop_texture: Texture2D = null
	if sprite and sprite.texture:
		crop_texture = sprite.texture
	
	Inventory.add_item(crop_type, harvest_yield, crop_texture)
	
	queue_free()
	return true
