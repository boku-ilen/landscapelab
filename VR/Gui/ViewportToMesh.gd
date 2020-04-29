extends MeshInstance


export(PackedScene) var viewport_element
export(bool) var create_collision_areas = false

onready var viewport = get_node("Viewport")
onready var viewport_texture = viewport_element.instance()
onready var area = get_node("Area")
# The size of the quad mesh itself.
onready var quad_mesh_size = mesh.size

var material = SpatialMaterial.new()
var last_pos2D


func _ready():
	viewport.add_child(viewport_texture)
	material.albedo_texture = viewport.get_texture()
	material.flags_unshaded = true
	material.flags_transparent = true
	set_surface_material(0, material)


func ray_interaction_input(from: Vector3, to: Vector3, event_type, pressed=true):
	var result = get_world().direct_space_state.intersect_ray(from, to, [], area.collision_layer, false, true)
	if not result.size() > 0:
		return
		
	var position3D = result.position
	
	position3D = area.global_transform.affine_inverse() * position3D
	
	var position2D = Vector2(position3D.x, -position3D.z)
	
	# Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
	# We need to convert it into the following range: 0 -> quad_size
	position2D.x += quad_mesh_size.x / 2
	position2D.y += quad_mesh_size.y / 2
	
	# Then we need to convert it into the following range: 0 -> 1
	position2D.x = position2D.x / quad_mesh_size.x
	position2D.y = position2D.y / quad_mesh_size.y
	
	# Finally, we convert the position to the following range: 0 -> viewport.size
	position2D.x = position2D.x * viewport.size.x
	position2D.y = position2D.y * viewport.size.y
	# We need to do these conversions so the event's position is in the viewport's coordinate system.
	
	var event = event_type.new()
	# If the event is a mouse motion event...
	if event is InputEventMouseMotion:
		# If there is not a stored previous position, then we'll assume there is no relative motion.
		if last_pos2D == null:
			event.relative = Vector2(0, 0)
		# If there is a stored previous position, then we'll calculate the relative position by subtracting
		# the previous position from the new position. This will give us the distance the event traveled from prev_pos
		else:
			event.relative = position2D - last_pos2D
	elif event is InputEventMouseButton:
		event.button_index = 1
		event.pressed = pressed
	
	# Update last_mouse_pos2D with the position we just calculated.
	last_pos2D = position2D
	# Set the event's position and global position.
	event.position = position2D
	event.global_position = position2D
	
	# Finally, send the processed input event to the viewport.
	viewport.input(event)


