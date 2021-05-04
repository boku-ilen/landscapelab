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
onready var center_node = get_node(center_node_path)

# TODO: all these will come from the configuration
var world_shift_check_period: float = 1
var world_shift_timer: float = 0
var height = 100

var is_fullscreen: bool = false

var shift_limit: float = Settings.get_setting("lod", "world-shift-distance")

# The offset
var x: int = 420821
var z: int = 453220


func _ready():
	inject_offset_properties()


func _process(delta):
	return  # FIXME: Disabled for now
	
	world_shift_timer += delta
	
	if world_shift_timer > world_shift_check_period:
		world_shift_timer = 0
		check_for_world_shift()


func _input(event):
	if event.is_action_pressed("exit_fullscreen") and is_fullscreen:
		TreeHandler.switch_last_state()
		is_fullscreen = false


# Shift the world if the player exceeds the bounds, in order to prevent coordinates from getting too big (floating point issues)
func check_for_world_shift():
	var delta_vec = Vector3(0, 0, 0)
	
	
	# Check x, z coordinates
	delta_vec.x = -shift_limit * floor(center_node.translation.x / shift_limit)
	delta_vec.z = -shift_limit * floor(center_node.translation.z / shift_limit)
	# (Height (y) probably doesn't matter, height differences won't be that big
	
	# Apply
	if delta_vec != Vector3(0, 0, 0):
		shift_world(delta_vec.x, delta_vec.z)


func shift_world(delta_x, delta_z):
	x += delta_x
	z += delta_z
	
	center_node.translation.x += delta_x
	center_node.translation.z += delta_z
	path_shifter.on_shift_world(delta_x, delta_z)
	spatial_shifter.on_shift_world(delta_x, delta_z)
	
	logger.debug("New offset: %d, %d" % [x, z])


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
	
	logger.debug("New offset: %d, %d" % [x, z])


func get_center():
	return [x, z]


# Converts engine coordinates to world coordinates (absolute webmercator coordinates).
# Works with Vector2 (top view) and Vector3.
func to_world_coordinates(pos):
	if pos is Vector2:
		return [x - int(pos.x), z - int(pos.y)]
	elif pos is Vector3:
		return [x - int(pos.x), int(pos.y), z - int(pos.z)]
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
