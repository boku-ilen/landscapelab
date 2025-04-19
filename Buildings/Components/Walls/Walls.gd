@tool
extends Node3D


#
# Plain (flat) walls for a building.
#


@export var wind_counterclockwise: bool = true
@export var material: Material = preload("res://Buildings/Components/Walls/PlainWalls.tres") :
		set(new_material):
			material = new_material
			$MeshInstance3D.material_override = material

var height = 2.5
# How much the texture shall be scaled with respect to the height
var texture_scale := Vector2(1., 1.)
var random_rotation := 0.
var random_90_rotation_rate := 0.

# Color modifier of the texture
var color
# To find the correct index from the sampler2DArray
var wall_idx := 0
var window_idx := 0


func _ready() -> void:
	$MeshInstance3D.material_override = material


func set_color(new_color):
	color = new_color


func set_wall_texture_index(new_wall_idx: int):
	wall_idx = new_wall_idx


func set_window_texture_index(new_window_idx: int):
	window_idx = new_window_idx


func set_lights_enabled(enabled):
	$MeshInstance3D.material_override.set_shader_parameter("lights_on", enabled)


func set_window_shading(enabled: bool):
	$MeshInstance3D.material_override.set_shader_parameter("window_shading", enabled)


func build(footprint: PackedVector2Array):
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(footprint)
	if rng.randf() < random_90_rotation_rate:
		random_rotation = PI/2
	
	var st = SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate flat normals - shaded as if round otherwise
	st.set_smooth_group(-1)
	
	# We want to essentially extrude the footprint, to create walls from lines.
	# Each two subsequent vertices should become a wall.
	# Sine each wall is a rectangle, each wall is composed of two triangles.
	# These triangles are created as follows when iterating over all points in the footprint:
	# First triangle: Current footprint point -> point above -> next footprint point
	# Second triangle: Next footprint point -> point above -> point above next footprint point
	
	if not Geometry2D.is_polygon_clockwise(footprint):
		footprint.reverse()
	
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
		
		# To add index for wall and window texture (repsectively in r, g)
		st.set_custom_format(0, SurfaceTool.CUSTOM_RG_HALF)
		 
		# Cast texture index to value between 0 and 1
		st.set_color(color.srgb_to_linear())
		st.set_custom(0, Color(wall_idx, window_idx, 0., 0.))
		
		# First triangle of the wall
		st.set_uv((Vector2(0.0, height) / texture_scale).rotated(random_rotation))
		st.set_uv2(Vector2(0.0, height))
		st.add_vertex(point_3d)
		
		st.set_uv(Vector2(0.0, 0.0) / texture_scale)
		st.set_uv2(Vector2(0.0, 0.0))
		st.add_vertex(point_up_3d)
		
		st.set_uv((Vector2(distance_to_next_point, height) / texture_scale).rotated(random_rotation))
		st.set_uv2(Vector2(distance_to_next_point, height))
		st.add_vertex(next_point_3d)
		
		# Second triangle of the wall
		st.set_uv((Vector2(distance_to_next_point, height) / texture_scale).rotated(random_rotation))
		st.set_uv2(Vector2(distance_to_next_point, height))
		st.add_vertex(next_point_3d)
		
		st.set_uv((Vector2(0.0, 0.0) / texture_scale).rotated(random_rotation))
		st.set_uv2(Vector2(0.0, 0.0))
		st.add_vertex(point_up_3d)
		
		st.set_uv((Vector2(distance_to_next_point, 0.0) / texture_scale).rotated(random_rotation))
		st.set_uv2(Vector2(distance_to_next_point, 0.0))
		st.add_vertex(next_point_up_3d)
	
	st.generate_normals()
	st.generate_tangents()
	
	# Apply
	var mesh = st.commit()
	mesh.custom_aabb = st.get_aabb()
	$MeshInstance3D.mesh = mesh
	
