extends GPUParticles3D
@tool


@export var spacing: float :
	get:
		return spacing # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_spacing
# Cardinal wind direction forces
# To achieve west and south use minus numbers
# For north in the shader: Vector3.FORWARD *= force
# For east in the shader: Vector3.RIGHT *= force
@export var wind_force_north: float :
	get:
		return wind_force_north # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_wind_force_north
@export var wind_force_east: float :
	get:
		return wind_force_east # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_wind_force_east
@export var scale_x := 1.5 :
	get:
		return scale_x # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_scale_x
@export var scale_y := 1.5 :
	get:
		return scale_y # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_scale_y
@export var shift_threshold := 30.0 :
	get:
		return shift_threshold # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_shift_threshold
@export var rows := 10 :
	get:
		return rows # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_rows

var center_node: Node3D :
	get:
		return center_node # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_center_node

func set_center_node(node: Node3D):
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


func set_rows(value: int):
	rows = value
	amount = pow(value, 2)
	process_material.set_shader_parameter("rows", int(rows))
	process_material.set_shader_parameter("amount", int(amount))


func set_shift_threshold(thresh: float):
	shift_threshold = thresh
	process_material.set_shader_parameter("shift_threshold", shift_threshold)


func set_visibility_aabb(a2b2: AABB):
	visibility_aabb = a2b2
	process_material.set_shader_parameter("droplet_start_height", a2b2.end.y)


func set_wind_force_north(force: float):
	wind_force_north = force
	process_material.set_shader_parameter("wind_force_north", force)


func set_wind_force_east(force: float):
	wind_force_east = force
	process_material.set_shader_parameter("wind_force_east", force)


func set_spacing(space: float) -> void:
	spacing = space
	process_material.set_shader_parameter("spacing", spacing)


func set_amount(how_many: int):
	amount = how_many
	process_material.set_shader_parameter("rows", int(sqrt(amount)))
	process_material.set_shader_parameter("amount", int(amount))


func set_scale_x(scl: float):
	scale_x = scl
	process_material.set_shader_parameter("scale_x", scale_x)


func set_scale_y(scl: float):
	scale_y = scl
	process_material.set_shader_parameter("scale_y", scale_y)


# Called when the node enters the scene tree for the first time.
func _ready():
	process_material.set_shader_parameter("spacing", spacing)
	process_material.set_shader_parameter("rows", int(sqrt(amount)))
	process_material.set_shader_parameter("amount", int(amount))
