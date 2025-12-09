extends TileMapLayer

@export var watered_duration = 90.0 # in seconds
@export var water_strength = 0.4
@export var waterable_tile: Array[int] = [6]

var wet_tiles := {}
var wet_overlays := {}

func _get_tile_size() -> Vector2:
	if tile_set == null:
		return Vector2(16, 16)
		
	return tile_set.test_size

func _process(delta: float) -> void:
	_update_wetness(delta)
	
func is_tile_waterable(tile_position) -> bool:
	var tile_id = get_cell_source_id(tile_position)
	print("Checking tile at ", tile_position, " - Tile ID: ", tile_id, " - Waterable IDs: ", waterable_tile)
	if tile_id == -1:
		print("No tile at this position!")
		return false
	var is_waterable = tile_id in waterable_tile	
	print("Is waterable: ", is_waterable)
	return is_waterable

func water(tile_position: Vector2i):
	print("Water called for tile: ", tile_position)
	print("Is waterable: ", is_tile_waterable(tile_position))
	if not is_tile_waterable(tile_position):
		print("Tile not waterable!")
		return
	
	if not wet_tiles.has(tile_position): ## if there's not a tile at the position the player is trying to water
		wet_tiles[tile_position] = watered_duration
		_create_wet_overlay(tile_position)
		print("Created overlay for tile: ", tile_position)
	else:
		print("Tile already wet, refreshing duration")
		wet_tiles[tile_position] = watered_duration

func _create_wet_overlay(tile_position: Vector2i):
	var overlay = Sprite2D.new()
	
	var img = Image.create(tile_set.tile_size.x, tile_set.tile_size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.4, 0.25, 0.15, water_strength))
	var texture = ImageTexture.create_from_image(img)
	
	overlay.texture = texture
	overlay.centered = true
	overlay.position = map_to_local(tile_position)
	overlay.z_index = 10
	
	get_parent().add_child(overlay)
	wet_overlays[tile_position] = overlay

func _update_wetness(delta):
	var finished = []
	
	## iterates through all the "wet" tiles
	for tile_position in wet_tiles.keys():
		wet_tiles[tile_position] -= delta
		var t = wet_tiles[tile_position] / watered_duration
		
		if t <= 0:
			finished.append(tile_position)
			t = 0
			
		if wet_overlays.has(tile_position):
			var overlay = wet_overlays[tile_position]
			overlay.modulate.a = water_strength * t
		
	## removes all the tiles in finished
	for tile_position in finished:
		wet_tiles.erase(tile_position)
		if wet_overlays.has(tile_position):
			wet_overlays[tile_position].queue_free()
			wet_overlays.erase(tile_position)

func is_tile_wet(tile_position: Vector2i) -> bool:
	if tile_position not in wet_tiles:
		return false
	return wet_tiles[tile_position] > 0
