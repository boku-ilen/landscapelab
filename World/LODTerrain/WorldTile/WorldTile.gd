tool
extends Spatial
class_name WorldTile

#
# This is a general world tile which can hold multiple meshes or other information (modules).
# To increase the LOD, it can split into 4 new tiles.
# The tiles are controlled via the TileHandler.
#

# Nodes
onready var modules = get_node("Modules")
onready var children = get_node("Children")

# Variables
var size : float
var size_with_skirt : float
var lod : int
var offset_from_parent : Vector2
var last_player_pos

var initialized = false # True when init() was called
var created = false # True when _ready() is done

var has_split = false # True when children are starting to be loaded
var done_loading = false # True when all modules in this tile have been loaded
var to_be_displayed = false # True when all modules in this tile want to be displayed
var to_be_deleted = false # True when this tile is waiting to be deleted

const NUM_CHILDREN = 4 # Number of children, will likely always stay 4 because it's a quadtree

var will_activate_with_last_player_pos # Can be set in init() to immediately activate the tile with a last_player_pos

var top_level: WorldTile = self # The top-level-tile of the tree this tile is in

# Settings
var max_lods = Settings.get_setting("lod", "distances")
var osm_start = Settings.get_setting("lod", "level-0-osm-zoom")
var subdiv : int = Settings.get_setting("lod", "default-tile-subdivision")

# Signals
signal tile_done_loading # Emitted once all modules have finished loading -> the tile is ready
signal tile_to_be_displayed # Emitted once all modules want to be displayed -> this tile is shown 
signal all_children_to_be_displayed # Emitted once all children want to be displayed
signal split # Emitted by the top-level tile when a child finished splitting, e.g. so the ground position can be updated

func _ready():
	# Set everything to invisible at the start to prevent flickering
	modules.visible = false
	children.visible = false
	
	connect("tile_to_be_displayed", self, "_on_tile_to_be_displayed")
	connect("all_children_to_be_displayed", self, "_on_all_children_to_be_displayed")
	
	PerformanceTracker.number_of_tiles += 1
	
	if initialized:
		if will_activate_with_last_player_pos:
			activate(will_activate_with_last_player_pos)
	else:
		logger.warning("WorldTile.init() wasn't called to fill this tile with its information before creating it. " +
		"This result in a broken tile!")
	
	created = true
	
	
func _process(delta):
	# If this tile is flagged to be deleted, all threads are done and all children are done deleting
	# as well, delete this tile!
	if done_loading and to_be_deleted and children.get_child_count() == 0:
		PerformanceTracker.number_of_tiles -= 1
		queue_free()
		return
		
	# Apply the visibility accordingly (this is done centrally here to avoid race conditions)
	# TODO: We don't really need to check this every frame, perhaps we can only do this after
	#  certain events (such as children having loaded, child tiles being deleted, etc) happened?
	#  If so, we need to be careful not to re-introduce race conditions!
	if to_be_displayed and not children.are_all_to_be_displayed():
		modules.visible = true
		children.visible = false
	else:
		modules.visible = false
		children.visible = true

# Sets the parameters needed to actually create the tile (must be called before adding to the scene tree = must be
# called before _ready()!)
func init(s, lod_level, activate_pos=null):
	size = s
	lod = lod_level
	
	# We add 2 to subdiv and increase the size by the added squares for the skirt around the mesh (which fills gaps
	# where things don't match up)
	size_with_skirt = size + (2.0/(subdiv + 1.0)) * size
	will_activate_with_last_player_pos = activate_pos
	
	initialized = true
	

# Called when all children are ready to be displayed.
# Actually, exactly this would happen in the next _process() call anyways. However,
# we also react immediately to the signal to prevent flickering.
func _on_all_children_to_be_displayed():
	modules.visible = false
	children.visible = true
	
	# Since new terrain is now displayed, we want to emit the 'split' signal in the topmost tile
	#  (which has no other tile parent)
	_emit_split_in_toplevel_tile()


# Emit the 'split' signal in the top-level tile (which has no tile parent)
func _emit_split_in_toplevel_tile():
	top_level.emit_signal("split")


func _on_tile_to_be_displayed():
	to_be_displayed = true


# Returns true if there is a layer of WorldTiles above this current one
func has_parent_tile():
	return get_parent().get_parent().is_in_group("WorldTile")


# Returns the parent WorldTile of this one, or null if there is none
func get_parent_tile():
	if has_parent_tile():
		return get_parent().get_parent()


# Creates a PlaneMesh which corresponds to the current size and subdivision
func create_tile_plane_mesh(add_skirt=true):
	var mesh = PlaneMesh.new()
	
	var mesh_size
	var mesh_subdiv = subdiv
	
	if add_skirt:
		mesh_size = size_with_skirt
		mesh_subdiv += 2 # Add 1 left and 1 right for the skirt
	else:
		mesh_size = size
	
	mesh.size = Vector2(mesh_size, mesh_size)
	
	mesh.subdivide_depth = mesh_subdiv
	mesh.subdivide_width = mesh_subdiv
	
	return mesh


# Sets the basic shader parameters which are required for getting positions or heights in the shader
func set_heightmap_params_for_obj(obj):
	obj.set_shader_param("subdiv", subdiv)
	obj.set_shader_param("size", size_with_skirt)
	obj.set_shader_param("size_without_skirt", size)


# Mark this tile (and thus its children) to be deleted as soon as it is safe to do so
func delete():
	children.clear_children()
	to_be_deleted = true
	
	
# Returns true if this is a leaf tile - it is being displayed and has no higher LOD children.
func is_leaf_tile():
	return !children.are_all_active()
	

# Returns the x and z position in a 2D vector
func get_pos_vector2d() -> Vector2:
	return Vector2(translation.x, translation.z)
	
	
# Returns a 2D vector with the tile size in both the x and the y field (since it is a square)
func get_size_vector2d() -> Vector2:
	return Vector2(size, size)


# Use the LOD at this tile (Make this mesh visible, and delete children modules) - for example, converge from 4 tiles
# to 1
func converge():
	if has_split:
		logger.debug("Tile converging to LOD %d" % [lod])
		
		children.clear_children()
		has_split = false


# Returns the height on the tile at a certain position (the y coordinate of the passed vector is ignored)
func get_height_at_position(var pos : Vector3):
	var used_tile = get_leaf_tile(pos)
	
	# If there is no TerrainColliderModule here, return 0
	if not used_tile.modules.has_node("TerrainColliderModule"):
		return 0
	
	return used_tile.modules.get_node("TerrainColliderModule").get_height_at_position(pos)
	

# Returns the given position, but with the y-coordinate set to be on the ground of the terrain.
func get_position_on_ground(var pos : Vector3):
	return Vector3(pos.x, get_height_at_position(pos), pos.z)


# Returns the child closest to the given position, or null if this is already a leaf tile, by going a step down the
# quad-tree.
func get_child_for_position(var pos : Vector3):
	if not is_leaf_tile():
		var gtranslation = global_transform.origin
		
		if pos.x > gtranslation.x:
			if pos.z > gtranslation.z:
				return children.get_node("3")
			else:
				return children.get_node("2")
		else:
			if pos.z > gtranslation.z:
				return children.get_node("1")
			else:
				return children.get_node("0")
	else:
		return null
		

# Returns the leaf tile that is most appropriate for a given position
func get_leaf_tile(var pos : Vector3):
	var child = get_child_for_position(pos)

	if child:
		return child.get_leaf_tile(pos)
	else:
		return self


# Returns the world position of the tile - used for server requests
# TODO: Actual server requests require -z because coordinates are stored differently in Godot -> separate function?
func get_true_position():
	return Offset.to_world_coordinates(global_transform.origin)


# Returns the OSM zoom level that corresponds to this tile - used for server requests
func get_osm_zoom():
	return lod + osm_start


# Called when the player is nearby - this makes the tile check whether it needs to split or converge, and do so if
# required.
func activate(player_pos):
	if !created: return
	
	last_player_pos = player_pos
	
	# Activate children with same pos
	for child in children.get_children():
		if child.has_method("activate"):
			child.activate(last_player_pos)
			
	var dist_to_player = get_dist_to_player()
	
	# Check whether this is a high LOD tile which needs to converge
	if done_loading:
		if lod > 0 and dist_to_player > max_lods[lod]:
			converge()
		elif lod < max_lods.size() - 1 and dist_to_player < max_lods[lod+1]:
			split(dist_to_player)


# Move the tile in the world (used for offsetting)
func move(delta):
	if !initialized: return
	
	translation += delta


# Returns the offset of the top left corner of this tile from the tile which is 'steps' above this one, as a Vector2
# with values between 0 and 1.
# Example: Bottom right tile (1 step) -> (0.5, 0.5)
# Example 2: Bottom right tile, top left tile (2 steps) -> (0.25, 0,25)
func get_offset_from_parents(steps):
	var offset = Vector2(0, 0)
	
	var current_node = self
	
	for walk_up in range(0, steps):
		offset = offset / 2 + current_node.offset_from_parent
		current_node = current_node.get_parent_tile()
		
	return offset


# Increase the LOD on this tile (Split the tile into 4 smaller tiles)
func split(dist_to_player):
	if !initialized: return
	
	# Don't split if we're already at the last max_lods item or have already split
	if lod >= max_lods.size() or has_split:
		return
	
	if is_leaf_tile():
		logger.debug("Tile splitting to LOD %d" % [lod + 1])
		
		has_split = true
		children.instantiate_children()


# Gets the distance of the center of the tile to the last known player location
func get_dist_to_player():
	# TODO: We can get the player_pos either like this, or via the last_player_pos variable.
	#  I believe the last_player_pos variable is actually not needed anymore, but it may be good for performance.
	#  This should be evaluated!
	var player_pos = PlayerInfo.get_engine_player_position()
	
	# Get closest point within rectangle to circle
	var clamped = Vector3()
	
	# Has to be global_transform.origin! Weird behaviour otherwise
	var gtranslation = global_transform.origin
	var origin = Vector2(gtranslation.x - size/2, gtranslation.z - size/2)
	var end = Vector2(gtranslation.x + size/2, gtranslation.z + size/2)
	
	clamped.x = clamp(player_pos.x, origin.x, end.x)
	clamped.z = clamp(player_pos.z, origin.y, end.y)

	return Vector2(player_pos.x, player_pos.z).distance_to(Vector2(clamped.x, clamped.z))
	

# Builds a request in the form of "/url_start/meter_x/meter_y/zoom.json" and returns the result, if it is valid.
func get_texture_result(url_start):
	var true_pos = get_true_position()
	
	var result = ServerConnection.get_json("/%s/%d.0/%d.0/%d.json"\
		% [url_start, -true_pos[0], true_pos[2], get_osm_zoom()])
		
	if not result or result.has("Error"):
		return null
		
	return result
	

# Add a function call to the ThreadPool at an appropriate priority based on the distance of
#  this tile to the player.
# Modules should use this function when using the ThreadPool to ensure that all modules of a
#  tile have the same priority.
func thread_task(object, function, arguments):
	var priority
	var dist_to_player = get_dist_to_player()
	
	if dist_to_player == 0:
		priority = 99.0 # FIXME
	else:
		# TODO: Temporary calculation: The closer this tile is to the player, the higher the priority.
		priority = (100000.0 / get_dist_to_player())
		
		# Also decrease priority by LOD
		priority /= (lod + 1)
	
	ThreadPool.enqueue_task(ThreadPool.Task.new(object, function, arguments), priority)
