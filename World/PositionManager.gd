extends Spatial
class_name PositionManager


"""This scene offers the possibility to use of the world of the LandscapeLab 
encapsulated. The general idea is to have a node which determines the current 
center position (in the graphic the VRTable/Player). 

The node above (PositionManager) then forwards this position to the Terrain nodes and
also manages Offset/Shifting-behaviour. Via the BaseTiles a very basic version 
of the world will be rendered. Additional geo-information are added in the 
LayerContainer. This can for instance be raster-data, such as vegetation 
(grass, trees, ...) but also vector-data, such as assets (existing wind-turbines)"""


export(NodePath) var center_node_path

onready var terrain = get_node("Terrain")
onready var path_shifter = get_node("Terrain/PathShiftingHandler")
onready var spatial_shifter = get_node("Terrain/SpatialShiftingHandler")
# FIXME: Should be center_node_path, but this generates errors due to inconsistencies in the node paths...
onready var center_node = get_node("FirstPersonPC")

# TODO: all these will come from the configuration
var world_shift_check_period: float = 1
var world_shift_timer: float = 0
var height = 100

var is_fullscreen: bool = false

var shift_limit: float = Settings.get_setting("lod", "world-shift-distance")

signal new_center(new_center_array)

# The offset
var x: int = 420500
var z: int = 453720

var delta_x := 0.0
var delta_z := 0.0

var loading = false

var _dependent_object_count := 0
var _dependent_objects_loaded := 0


func _ready():
	inject_offset_properties()


func _process(delta):
	world_shift_timer += delta
	
	if world_shift_timer > world_shift_check_period:
		world_shift_timer = 0
		_check_for_world_shift()


func _input(event):
	if event.is_action_pressed("exit_fullscreen") and is_fullscreen:
		TreeHandler.switch_last_state()
		is_fullscreen = false


# Shift the world if the player exceeds the bounds, in order to prevent coordinates from getting too big (floating point issues)
func _check_for_world_shift():
	var delta_squared = Vector2(center_node.translation.x, center_node.translation.z).length_squared()
	
	if (delta_squared > pow(shift_limit, 2)) and not loading:
		_shift_world(center_node.translation.x, center_node.translation.z)


# Begin the process of world shifting by setting the new offset variables and emitting a signal.
func _shift_world(delta_x, delta_z):
	logger.info("Shifting world by %f, %f" % [delta_x, delta_z])
	
	loading = true
	_dependent_objects_loaded = 0
	
	self.delta_x = delta_x
	self.delta_z = delta_z
	
	emit_signal("new_center", [x + delta_x, z - delta_z])
	
	# If there are no objects we need to wait for, apply the new position right away.
	# Otherwise, we'll wait until all dependent objects are done loading.
	if _dependent_object_count == 0:
		_apply_new_position_to_center_node()


# Move the center_node according to the last known position delta.
# This should be called in the same frame as the new data is being displayed for a seamless transition.
func _apply_new_position_to_center_node():
	center_node.translation.x -= delta_x
	center_node.translation.z -= delta_z
	
	x += delta_x
	z -= delta_z
	
	loading = false


func inject_offset_properties():
	# Inject into the center node
	if center_node and "position_manager" in center_node:
		center_node.position_manager = self
	
	# Inject into the terrain
	for child in terrain.get_children():
		if "center_node" in child:
			child.center_node = center_node
		if "position_manager" in child:
			child.position_manager = self


# Sets the current divergence between engine coordinates and world coordinates.
func set_offset(new_x, new_z):
	x = new_x
	z = new_z
	
	# FIXME: shift the world accordingly (or remove this function entirely? currently unused)
	
	logger.debug("New offset: %d, %d" % [x, z])


func get_center():
	return [x, z]


# Add a signal to wait for until the new offset is applied to the center_node.
# Useful for synchronizing the displaying of new data all at once.
func add_signal_dependency(object, signal_name):
	object.connect(signal_name, self, "_on_dependent_object_loaded")
	_dependent_object_count += 1


func _on_dependent_object_loaded():
	_dependent_objects_loaded += 1
	
	if _dependent_objects_loaded == _dependent_object_count:
		_apply_new_position_to_center_node()


# Converts engine coordinates to world coordinates (absolute webmercator coordinates).
# Works with Vector2 (top view) and Vector3.
func to_world_coordinates(pos):
	if pos is Vector2:
		return [x - int(pos.x), z - int(pos.y)]
	elif pos is Vector3:
		return [x + int(pos.x), int(pos.y), z - int(pos.z)]
	else:
		logger.warning("Invalid type for to_world_coordinates: %s;"\
			+ "supported types: Vector2, Vector3" % [typeof(pos)])


# Converts world coordinates (absolute webmercator coordinates) to engine coordinates.
# Works with Vector2 (top view) and Vector3.
func to_engine_coordinates(pos):
	if pos is Array and pos.size() == 2:
		return Vector2(x - pos[0], -pos[1] + z)
	elif pos is Array and pos.size() == 3:
		return Vector3(x - pos[0], pos[1], -pos[2] + z)
	else:
		logger.warning("Invalid type for to_engine_coordinates: %s; Needs to be Array with length of 2 or 3"
		 % [String(typeof(pos))])


# Converts any position from array to vector of vice versa
func change_position_format(pos):
	if pos is Array and pos.size() == 2:
		return Vector2(pos[0], pos[1])
	elif pos is Array and pos.size() == 3:
		return Vector3(pos[0], pos[1], pos[2])
	elif pos is Vector2:
		return [pos[0], pos[1]]
	elif pos is Vector3:
		return [pos[0], pos[1], pos[2]]


# Return an array with the minimum and maximum x and z values in all rendered layers.
func get_rendered_boundary() -> Array:
	# TODO: get all Layers and calculate their maximum boundary
	return [0, 1000000, 0, 1000000]
