tool
extends Spatial


#
# Plain (flat) walls for a building.
#


export(bool) var wind_counterclockwise = true

var height = 2.5
var texture_scale = 2.5  # Size of the texture in meters - likely identical to the height

var color


func _ready():
	$MeshInstance.material_override = preload("res://Buildings/Components/PlainWalls.tres")
#	$MeshInstance.material_override.set_shader_param("texture_albedo", albedo)
#	$MeshInstance.material_override.set_shader_param("texture_normal", normalmap)
#	# TODO: Should stay the same for identical buildings
#	$MeshInstance.material_override.set_shader_param("random_seed", randi())


func set_color(new_color):
	color = new_color


func set_lights_enabled(enabled):
	$MeshInstance.material_override.set_shader_param("lights_on", enabled)


func set_window_shading(enabled: bool):
	$MeshInstance.material_override.set_shader_param("window_shading", enabled)


func build(footprint: PoolVector2Array):
	var st = SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# We want to essentially extrude the footprint, to create walls from lines.
	# Each two subsequent vertices should become a wall.
	# Sine each wall is a rectangle, each wall is composed of two triangles.
	# These triangles are created as follows when iterating over all points in the footprint:
	# First triangle: Current footprint point -> point above -> next footprint point
	# Second triangle: Next footprint point -> point above -> point above next footprint point
	
	for i in range(0, footprint.size()):
		var point_3d = Vector3(footprint[i].x, 0, footprint[i].y)
		var point_up_3d = point_3d + Vector3.UP * height
		
		var next_i = i + 1
		
		# If we're at the last index, loop back to the start to build the last wall
		if next_i >= footprint.size():
			next_i = 0
		
		var next_point_3d = Vector3(footprint[next_i].x, 0, footprint[next_i].y)
		var next_point_up_3d = next_point_3d + Vector3.UP * height
		
		# The distance is needed for the UV coordinates, to make the texture not stretch but repeat
		var distance_to_next_point = max(0.1, point_3d.distance_to(next_point_3d)) # to prevent division by 0
		
		if (wind_counterclockwise):
			var tangent_plane = Plane(next_point_3d, point_up_3d, point_3d)
			st.add_tangent(tangent_plane)
			st.add_color(color)
			
			# First triangle of the wall
			st.add_uv(Vector2(distance_to_next_point, 0.0) / texture_scale)
			st.add_vertex(next_point_3d)
			
			st.add_uv(Vector2(0.0, height) / texture_scale)
			st.add_vertex(point_up_3d)
			
			st.add_uv(Vector2(0.0, 0.0))
			st.add_vertex(point_3d)
			
			# Second triangle of the wall
			st.add_uv(Vector2(distance_to_next_point, height) / texture_scale)
			st.add_vertex(next_point_up_3d)
			
			st.add_uv(Vector2(0.0, height) / texture_scale)
			st.add_vertex(point_up_3d)
			
			st.add_uv(Vector2(distance_to_next_point, 0.0) / texture_scale)
			st.add_vertex(next_point_3d)
		else:
			var tangent_plane = Plane(point_3d, point_up_3d, next_point_3d)
			st.add_tangent(tangent_plane)
			st.add_color(color)
			
			# First triangle of the wall
			st.add_uv(Vector2(0.0, 0.0))
			st.add_vertex(point_3d)
			
			st.add_uv(Vector2(0.0, height) / texture_scale)
			st.add_vertex(point_up_3d)
			
			st.add_uv(Vector2(distance_to_next_point, 0.0) / texture_scale)
			st.add_vertex(next_point_3d)
			
			# Second triangle of the wall
			st.add_uv(Vector2(distance_to_next_point, 0.0) / texture_scale)
			st.add_vertex(next_point_3d)
			
			st.add_uv(Vector2(0.0, height) / texture_scale)
			st.add_vertex(point_up_3d)
			
			st.add_uv(Vector2(distance_to_next_point, height) / texture_scale)
			st.add_vertex(next_point_up_3d)
	
	st.generate_normals()
	
	# Apply
	var mesh = st.commit()
	$MeshInstance.mesh = mesh
	
	
