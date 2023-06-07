extends LayerCompositionRenderer


var chunks = []

var chunk_size = 200
var extent = 3


func _ready():
	super._ready()
	for x in range(-extent, extent + 1):
		for y in range(-extent, extent + 1):
			var chunk = preload("res://Layers/Renderers/VectorVegetation/PlantMultiMeshInstance.tscn").instantiate()

			var size = chunk_size
			var chunk_position = Vector3(x * size, 0.0, y * size)

			chunk.position = chunk_position
			chunk.size = size
			
			chunk.height_layer = layer_composition.render_info.height_layer
			chunk.plant_layer = layer_composition.render_info.plant_layer

			chunks.append(chunk)
	
	for chunk in chunks:
		$Chunks.add_child(chunk)


func is_new_loading_required(position_diff: Vector3) -> bool:
	if abs(position_diff.x) > chunk_size or abs(position_diff.z) > chunk_size:
		return true
	else:
		return false


func full_load():
	for chunk in chunks:
		chunk.position_diff_x = 0
		chunk.position_diff_z = 0
		
		chunk.load_new_data(center[0] + chunk.position.x, center[1] - chunk.position.z)
	


func adapt_load(_diff: Vector3):
	for chunk in chunks:
		chunk.position_diff_x = 0.0
		chunk.position_diff_z = 0.0

		var changed = false

		if chunk.position.x - position_manager.center_node.position.x >= chunk_size * extent:
			chunk.position_diff_x = -chunk_size * extent * 2 - chunk_size
			changed = true
		if chunk.position.x - position_manager.center_node.position.x <= -chunk_size * extent:
			chunk.position_diff_x = chunk_size * extent * 2 + chunk_size
			changed = true
		if chunk.position.z - position_manager.center_node.position.z >= chunk_size * extent:
			chunk.position_diff_z = -chunk_size * extent * 2 - chunk_size
			changed = true
		if chunk.position.z - position_manager.center_node.position.z <= -chunk_size * extent:
			chunk.position_diff_z = chunk_size * extent * 2 + chunk_size
			changed = true
		
		if changed:
			chunk.load_new_data(center[0] + chunk.position.x + chunk.position_diff_x, center[1] - chunk.position.z - chunk.position_diff_z)
	
	call_deferred("apply_new_data")


func apply_new_data():
	for chunk in $Chunks.get_children():
		if chunk.changed:
			chunk.position.x += chunk.position_diff_x
			chunk.position.z += chunk.position_diff_z
			
			chunk.apply_new_data()
	
	logger.info("Applied new VectorVegetationRenderer data for %s" % [name])
