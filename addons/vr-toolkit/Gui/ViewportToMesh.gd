extends MeshInstance
tool


export(PackedScene) var viewport_element setget set_up_viewport
export(bool) var interactable = true
export(Vector2) var mesh_size setget set_mesh_size

onready var viewport = get_node("Viewport")
onready var area = get_node("Area")
onready var collision_shape = get_node("Area/CollisionShape")

# The size of the quad mesh itself.
var quad_mesh_size: Vector2
var material = SpatialMaterial.new()
var last_pos2D
var viewport_texture


func set_mesh_size(size):
	mesh_size = size
	if self.mesh.has_method("get_size"):
		if not mesh_size == Vector2(0,0):
			mesh.size = mesh_size
		quad_mesh_size = mesh.size
	else:
		quad_mesh_size = mesh_size


func set_up_viewport(element):
	# Remove all children or else they will stay
	for child in $Viewport.get_children():
		$Viewport.remove_child(child)
	
	# Reset the surface material if unset
	if element == null:
		viewport_element = null
		set_surface_material(0, null)
		return
		
	# So the viewport size does not have to be set manually
	viewport_element = element
	viewport_texture = element.instance()
	if viewport_texture is Control:
		$Viewport.size = viewport_texture.rect_size
	
	$Viewport.add_child(viewport_texture)
	material.albedo_texture = $Viewport.get_texture()
	material.flags_unshaded = true
	material.flags_transparent = true
	set_surface_material(0, material)


func _ready():
	if interactable:
		collision_shape.shape = BoxShape.new()
		collision_shape.shape.extents = Vector3(quad_mesh_size.x / 2, 0.001, quad_mesh_size.y / 2)
	else:
		collision_shape.disabled = true


func ray_interaction_input(position3D: Vector3, event_type, device_id, pressed=null):
	# The position3D will be transformed affinly so it is  the actual values for the viewport and not those in the world.
	position3D = area.global_transform.affine_inverse() * position3D
	# And then changed to a 2D-Vector that is on the area of the collision shape
	# As the instance is rotated by 90 degrees it will be x and z axis
	var position2D = Vector2(position3D.x, position3D.z)
	
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
	
	# Set the id of the device to the id of the controller
	event.device = device_id
	
	# Finally, send the processed input event to the viewport.
	viewport.input(event)


