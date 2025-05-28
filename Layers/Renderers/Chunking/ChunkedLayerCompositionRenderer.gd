extends LayerCompositionRenderer
class_name ChunkedLayerCompositionRenderer


var chunks: Array[RenderChunk] = []
var waiting_to_apply := false

@export var chunk_size := 1000.0
@export var extent := 5

@export var chunk_scene: PackedScene
@export var detailed_load_distance := 2000.0


func custom_chunk_setup(chunk): pass


func _ready():
	super._ready()
	
	for x in range(-extent, extent + 1):
		for y in range(-extent, extent + 1):
			var chunk = chunk_scene.instantiate()

			chunk.position = Vector3(x * chunk_size, 0.0, y * chunk_size)
			chunk.size = chunk_size
			
			custom_chunk_setup(chunk)
			
			# Start as a lowest quality chunk
			chunk.decrease_quality(INF)
			
			chunks.append(chunk)
	
	for chunk in chunks:
		$Chunks.add_child(chunk)


func is_new_loading_required(position_diff: Vector3) -> bool:
	return not waiting_to_apply and (abs(position_diff.x) > chunk_size or abs(position_diff.z) > chunk_size)


func full_load():
	for chunk in chunks:
		chunk.position_diff = Vector3.ZERO
		
		chunk.build(center[0], center[1])


func adapt_load(_diff: Vector3):
	super.adapt_load(_diff)
	
	if waiting_to_apply: return
	
	# Because this function is called in a thread, the player position might change while the loop
	#  below is running. In order to get consistent results, we need to cache one definitive
	#  player position here.
	var player_x = position_manager.center_node.position.x
	var player_z = position_manager.center_node.position.z
	
	for chunk in chunks:
		var changed = false
		chunk.position_diff.x = 0
		chunk.position_diff.z = 0

		while chunk.position.x + chunk.position_diff.x - player_x >= chunk_size * extent + chunk_size / 2.0:
			chunk.position_diff.x += -chunk_size * extent * 2 - chunk_size
			changed = true
		while chunk.position.x + chunk.position_diff.x - player_x <= -chunk_size * extent - chunk_size / 2.0:
			chunk.position_diff.x += chunk_size * extent * 2 + chunk_size
			changed = true
		
		while chunk.position.z + chunk.position_diff.z - player_z >= chunk_size * extent + chunk_size / 2.0:
			chunk.position_diff.z += -chunk_size * extent * 2 - chunk_size
			changed = true
		while chunk.position.z + chunk.position_diff.z - player_z <= -chunk_size * extent - chunk_size / 2.0:
			chunk.position_diff.z += chunk_size * extent * 2 + chunk_size
			changed = true
		
		if changed:
			chunk.decrease_quality(INF)  # Definitely maximally decrease quality here
			chunk.build(center[0], center[1])
	
	waiting_to_apply = true
	call_deferred("apply_new_data")


func get_nearest_low_quality_chunk(query_position: Vector3):
	var nearest_distance = INF
	var nearest_chunk
	
	for chunk in chunks:
		var distance = Vector2(chunk.position.x, chunk.position.z).distance_to(Vector2(query_position.x, query_position.z))
		if distance < nearest_distance and chunk.can_increase_quality(distance):
			nearest_distance = distance
			nearest_chunk = chunk
	
	return nearest_chunk


func refine_load():
	super.refine_load()
	
	if waiting_to_apply: return
	
	var any_change_done = false
	
	# Downgrade chunks which are now too far away
	for chunk in chunks:
		var distance = Vector2(chunk.position.x, chunk.position.z).distance_to(Vector2(position_manager.center_node.position.x, position_manager.center_node.position.z))
		if chunk.decrease_quality(distance):
			chunk.build(center[0], center[1])
			any_change_done = true
	
	# Upgrade nearby chunks
	var nearest_chunk = get_nearest_low_quality_chunk(position_manager.center_node.position)
	
	if nearest_chunk and not nearest_chunk.changed:
		var distance = Vector2(nearest_chunk.position.x, nearest_chunk.position.z).distance_to(Vector2(position_manager.center_node.position.x, position_manager.center_node.position.z))
		if nearest_chunk.increase_quality(distance):
			nearest_chunk.build(center[0], center[1])
			any_change_done = true
	
	if any_change_done:
		waiting_to_apply = true
		call_deferred("apply_new_data")


func apply_new_data():
	for chunk in $Chunks.get_children():
		if chunk.changed:
			chunk.apply()
			
			chunk.position += chunk.position_diff
			chunk.position_diff = Vector3.ZERO
	
	logger.info("Applied new chunked data for %s" % [name])
	waiting_to_apply = false


func get_debug_info() -> String:
	return "{0} chunks with a maximum size of {1} m.".format([
		chunks.size(),
		chunks.back().size if not chunks.is_empty() else ""
	])
