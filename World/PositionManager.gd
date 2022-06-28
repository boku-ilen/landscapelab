extends Node
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

var center_node: Spatial setget set_center_node
var terrain setget set_terrain
var layer_configurator: Node setget set_layer_configurator

var _previous_center_node_position := Vector2.ZERO
var _center_node_velocity := Vector2.ZERO

# TODO: all these will come from the configuration
var world_shift_check_period: float = 0.5
var world_shift_timer: float = 0

var standing_shift_limit := 50.0
var moving_shift_limit := 400.0
var moving_shift_time_factor := 1.0

var height = 100

var shift_limit: float = Settings.get_setting("lod", "world-shift-distance")

signal new_center(new_center_array)
signal new_center_node(node)

# The offset
var x: int
var z: int

var delta_x := 0.0
var delta_z := 0.0

var loading = false

var _dependent_object_count := 0
var _dependent_objects_loaded := 0

# Fallback height for conversions where no height is given, but the output expects one
const DEFAULT_HEIGHT = 500
const LOG_MODULE := "WORLDPOSITION"


func set_terrain(terr: Spatial):
	terrain = terr
	
	# Inject into the terrain
	for child in terrain.get_children():
		if "position_manager" in child:
			child.position_manager = self
	
	set_center_node(get_node(center_node_path))


func get_center_node_engine_position():
	return center_node.translation


func get_center_node_world_position():
	return to_world_coordinates(center_node.translation)


func translate_center_node(new_x, new_z):
	pass


func set_center_node(node: Spatial):
	center_node = node
	# Inject into the center node
	if "position_manager" in node:
		center_node.position_manager = self
	
	# Inject into the terrain
	for child in terrain.get_children():
		if "center_node" in child:
			child.center_node = node
	
	emit_signal("new_center_node", node)


func set_layer_configurator(configurator: Node):
	layer_configurator = configurator
	layer_configurator.connect("center_changed", self, "set_offset")
	x = layer_configurator.center.x
	z = layer_configurator.center.z


func _process(delta):
	# Calculate center node velocity
	var current_center_node_position = Vector2(center_node.translation.x, center_node.translation.z)
	_center_node_velocity = (current_center_node_position - _previous_center_node_position) / delta
	_previous_center_node_position = current_center_node_position
	
	world_shift_timer += delta
	
	if world_shift_timer > world_shift_check_period:
		world_shift_timer = 0
		_check_for_world_shift()


# Shift the world if the player exceeds the bounds, in order to prevent coordinates from getting too big (floating point issues)
func _check_for_world_shift():
	var delta_squared = Vector2(center_node.translation.x, center_node.translation.z).length_squared()
	
	# Shift the world if we're standing, or if we've moved quite a bit
	if ((_center_node_velocity == Vector2.ZERO and (delta_squared > pow(standing_shift_limit, 2))) \
			or ((delta_squared > pow(moving_shift_limit, 2)))) and not loading:
		# Shift towards the movement velocity in order to have data approximately where we're going
		# TODO: Instead of the hardcoded 5 second estimate, we could take the previous loading time
		#  But for this we need to have access to the LayerRenderers node here
		_shift_world(center_node.translation.x + _center_node_velocity.x * moving_shift_time_factor,
				center_node.translation.z + _center_node_velocity.y * moving_shift_time_factor)


# Begin the process of world shifting by setting the new offset variables and emitting a signal.
func _shift_world(delta_x, delta_z):
	# Make sure the shifting lines up with the most coarse grid (e.g. of the terrain) in order to
	# avoid differences within same-LOD areas after shifting
	# TODO: Generalize this factor; config or calculate from other values?
	delta_x -= fposmod(delta_x, 16)
	delta_z -= fposmod(delta_z, 16)
	
	logger.info("Shifting world by %f, %f" % [delta_x, delta_z], LOG_MODULE)
	
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
	if center_node:
		center_node.translation.x -= delta_x
		center_node.translation.z -= delta_z
	
	x += delta_x
	z -= delta_z
	
	loading = false


# Sets the current divergence between engine coordinates and world coordinates.
func set_offset(new_x, new_z):
	x = new_x
	z = new_z
	
	emit_signal("new_center", [x, z])
	delta_x = 0
	delta_z = 0
	
	logger.debug("New offset: %d, %d" % [x, z], LOG_MODULE)


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
			+ "supported types: Vector2, Vector3" % [typeof(pos)], LOG_MODULE)


# Converts world coordinates (absolute webmercator coordinates) to engine coordinates.
# Works with 2D and 3D arrays and Vectors, but always returns a Vector3.
func to_engine_coordinates(pos) -> Vector3:
	if pos is Array and pos.size() == 2:
		return Vector3(-x + pos[0], DEFAULT_HEIGHT, -pos[1] + z)
	elif pos is Array and pos.size() == 3:
		return Vector3(x - pos[0], pos[1], -pos[2] + z)
	elif pos is Vector3:
		return Vector3(-x + pos.x, pos.y, -pos.z + z)
	else:
		logger.warning("Invalid type for to_engine_coordinates: %s; Needs to be Array with length of 2 or 3"
		 % [String(typeof(pos))], LOG_MODULE)
		return Vector3(0, 0, 0)


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
