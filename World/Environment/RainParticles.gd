extends GPUParticles3D


@export var spacing: float :
	get:
		return spacing
	set(space):
		spacing = space
		process_material.set_shader_parameter("spacing", spacing)

# Cardinal wind direction forces
# To achieve west and south use minus numbers
# For north in the shader: Vector3.FORWARD *= force
# For east in the shader: Vector3.RIGHT *= force
@export var wind_force_north: float :
	get:
		return wind_force_north
	set(force):
		wind_force_north = force
		process_material.set_shader_parameter("wind_force_north", force)

@export var wind_force_east: float :
	get:
		return wind_force_east
	set(force):
		wind_force_east = force
		process_material.set_shader_parameter("wind_force_east", force)

@export var scale_x := 1.5 :
	get:
		return scale_x
	set(scl):
		scale_x = scl
		process_material.set_shader_parameter("scale_x", scale_x)

@export var scale_y := 1.5 :
	get:
		return scale_y
	set(scl):
		scale_y = scl
		process_material.set_shader_parameter("scale_y", scale_y)

@export var shift_threshold := 30.0 :
	get:
		return shift_threshold
	set(thresh):
		shift_threshold = thresh
		process_material.set_shader_parameter("shift_threshold", shift_threshold)

@export var rows := 10 :
	get:
		return rows
	set(value):
		rows = value
		amount = int(pow(value, 2))
		process_material.set_shader_parameter("rows", int(rows))
		process_material.set_shader_parameter("amount", int(amount))

var center_node: Node3D :
	get:
		return center_node
	set(node):
		if center_node:
			center_node.get_node("RainRemoteTransform").queue_free()
		center_node = node
		var rt = RemoteTransform3D.new()
		rt.name = "RainRemoteTransform"
		rt.remote_path = get_path()
		rt.update_rotation = false
		rt.update_scale = false
		rt.update_position = true
		node.add_child(rt)


# Setters for native member variables
func _set(property, value):
	if property == "visibility_aabb":
		visibility_aabb = value
		process_material.set_shader_parameter("droplet_start_height", value.end.y)
	elif property == "amount":
		amount = value
		process_material.set_shader_parameter("rows", int(sqrt(value)))
		process_material.set_shader_parameter("amount", int(value))


func _ready():
	process_material.set_shader_parameter("spacing", spacing)
	process_material.set_shader_parameter("rows", int(sqrt(amount)))
	process_material.set_shader_parameter("amount", int(amount))
