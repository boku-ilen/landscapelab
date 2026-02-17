extends Node3D

var height_layer: GeoRasterLayer
var center: Array


func _ready():
	var largest_height_difference = -INF
	var angle_to_apply = 0.0
	
	# Check how to best orient
	print("check")
	for i in range(12):
		var angle = i * ((2.0 * PI) / 12.0)
		
		rotation.y = angle
		
		var height_at_front = get_height_at_world_position($LowerFront/FrontHeightSamplePoint.global_position)
		var height_at_back = get_height_at_world_position($HigherBack/BackHeightSamplePoint.global_position)
		
		var height_difference_here = height_at_back - height_at_front
		
		print(height_difference_here)
		
		if height_difference_here > largest_height_difference:
			angle_to_apply = angle
			largest_height_difference = height_difference_here
	
	rotation.y = angle_to_apply
	
	var height_at_front = get_height_at_world_position($LowerFront/FrontHeightSamplePoint.global_position)
	var height_at_back = get_height_at_world_position($HigherBack/BackHeightSamplePoint.global_position)
	
	$LowerFront/FrontHeightSamplePoint.global_position.y = height_at_front
	$HigherBack/BackHeightSamplePoint.global_position.y = height_at_back
	$Weir.mesh.size.y = largest_height_difference + 3.0
	$Side1.mesh.size.y = largest_height_difference + 5.0
	$Side2.mesh.size.y = largest_height_difference + 5.0
	
	$HigherBack.material_override.set_shader_parameter("height", height_at_back)
	$LowerFront.material_override.set_shader_parameter("height", height_at_front)
	
	HeightOverlay.updated.emit()


func get_height_at_world_position(world_position):
	var globalized_position = Vector3(center[0], 0.0, center[1]) + Vector3(world_position.x, 0.0, -world_position.z)
	return height_layer.get_value_at_position(globalized_position.x, globalized_position.z)
