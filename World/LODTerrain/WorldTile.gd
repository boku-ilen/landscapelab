tool
extends Spatial

#
# This is a general world tile which can hold multiple meshes or other information (modules).
# To increase the LOD, it can split into 4 new tiles.
# The tiles are controlled via the TileSpawner.
#

# Nodes
onready var this_scene = load("res://World/LODTerrain/WorldTile.tscn")
onready var modules = get_node("Modules")
onready var children = get_node("Children")

# Variables
var size : float
var size_with_skirt : float
var lod : int
var offset_from_parent : Vector2

var has_split = false
var initialized = false

var created = false
var last_player_pos
var subdiv_mod = 1

var subdiv : int = 16

var num_modules : int = 0 # Number of modules this tile has
var num_modules_loaded : int = 0 # Incremented when a module finishes loading

const NUM_CHILDREN = 4 # Number of children, will likely always stay 4 because it's a quadtree
var num_children_loaded : int = 0 # Incremented when a child finishes loading

var will_activate_with_last_player_pos # Can be set in init() to immediately activate the tile with a last_player_pos

# Settings
var max_lods = Settings.get_setting("lod", "distances")
var module_path = Settings.get_setting("lod", "module-path")
var module_scenes = Settings.get_setting("lod", "modules")
var osm_start = Settings.get_setting("lod", "level-0-osm-zoom")

# Signals
signal module_done_loading # Emitted by modules once they've finished loading and are ready to be displayed
signal tile_done_loading # Emitted by the tile once all modules have finished loading -> the tile is ready


func _ready():
	connect("module_done_loading", self, "_on_module_done_loading")
	
	if initialized:
		spawn_modules()

		if will_activate_with_last_player_pos:
			activate(will_activate_with_last_player_pos)
	else:
		print("Warning: Uninitialized WorldTile created")
	
	created = true


func spawn_modules():
	var index = 0
	var modules_to_spawn = []
	
	# Get the number of modules and select the modules we will want to spawn
	for mds in module_scenes:
		if index <= lod: # This tile's lod is equal to or greater than the module's requirement -> spawn it
			for md in mds:
				num_modules += 1
				modules_to_spawn.append(load(module_path + md).instance() as Module)
		else:
			break; # We arrived at the higher LODs, which means we can stop now
			
		index += 1
	
	# Spawn the modules we selected previously
	for module in modules_to_spawn:
		modules.add_child(module)


# Sets the parameters needed to actually create the tile (must be called before adding to the scene tree = must be
# called before _ready()!)
func init(s, lod_level, activate_pos=null, _subdiv_mod=1):
	size = s
	lod = lod_level
	subdiv_mod = _subdiv_mod
	
	initialized = true
	
	will_activate_with_last_player_pos = activate_pos


# Called when the module_done_loading signal is emitted.
# If all modules are now done, emits tile_done_loading
func _on_module_done_loading():
	num_modules_loaded += 1
	
	if num_modules_loaded == num_modules:
		emit_signal("tile_done_loading")


# Called when a child tile is done loading.
# If all children are done loading, they are displayed instead of this tile.
func _on_child_tile_finished():
	num_children_loaded += 1
	
	if num_children_loaded == NUM_CHILDREN:
		display_children_instead_of_self()


# Returns true if there is a layer of WorldTiles above this current one
func has_parent_tile():
	return get_parent().get_parent().is_in_group("WorldTile")


# Returns the parent WorldTile of this one, or null if there is none
func get_parent_tile():
	if has_parent_tile():
		return get_parent().get_parent()


# Make all children tiles visible, and all of this tile's modules invisible
func display_children_instead_of_self():
	children.visible = true
	set_modules_invisible()


# Creates a PlaneMesh which corresponds to the current size and subdivision
func create_tile_plane_mesh():
	var mesh = PlaneMesh.new()
	
	# We add 2 to subdiv and increase the size by the added squares for the skirt around the mesh (which fills gaps
	# where things don't match up)
	size_with_skirt = size + (2.0/(subdiv + 1.0)) * size
	mesh.size = Vector2(size_with_skirt, size_with_skirt)
	
	mesh.subdivide_depth = subdiv + 2 # Add 1 left and 1 right for the skirt
	mesh.subdivide_width = subdiv + 2
	
	return mesh


# Sets the basic shader parameters which are required for getting positions or heights in the shader
func set_heightmap_params_for_obj(obj):
	obj.set_shader_param("subdiv", subdiv)
	obj.set_shader_param("size", size_with_skirt)
	obj.set_shader_param("size_without_skirt", size)


# Removes all the higher LOD children
func clear_children():
	for child in children.get_children():
		child.queue_free()
		
	num_children_loaded = 0


# Hides the mesh at this LOD - used when higher LOD children are shown instead
func set_modules_invisible():
	modules.visible = false
	
	
# Returns true if this is a leaf tile - it is being displayed and has no higher LOD children.
func is_leaf_tile():
	return modules.visible


# Use the LOD at this tile (Make this mesh visible, and delete children modules) - for example, converge from 4 tiles
# to 1
func converge():
	modules.visible = true
	clear_children()
	has_split = false


# Returns the height on the tile at a certain position (the y coordinate of the passed vector is ignored)
func get_height_at_position(var pos : Vector3):
	var used_tile = get_leaf_tile(pos)
		
	if not used_tile.modules.has_node("TerrainColliderModule"):
		# TODO: What to do if it is impossible to get a height at that position?
		return -200
	
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
	var tile = self
	
	while not tile.is_leaf_tile():
		tile = tile.get_child_for_position(pos)
		
	return tile


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
	if dist_to_player > max_lods[lod]:
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
	
	if lod >= max_lods.size(): return # Don't split if we're already at the last max_lods item
	
	if has_split:
		return
		
	has_split = true
	
	#ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_instantiate_children", [_subdiv_mod]))
	_instantiate_children([1])


# Here, the actual splitting happens - this function can be run in a thread
func _instantiate_children(data):
	# The children are simply named from 0 to 3:
	#  ----> x
	# | 0 2
	# | 1 3
	# v y
	var cur_name = 0
	
	# Hide children while they're being built
	children.visible = false
	
	# Add 4 children
	for x in range(0, 2):
		for y in range(0, 2):
			var xy_vec = Vector2(x, y)
			
			var child = this_scene.instance()
			
			# Set location
			var offset = Vector3(x - 0.5, 0, y - 0.5)  * size/2.0
			child.translation = offset
			
			child.offset_from_parent = xy_vec / 2 # fields are 0 or 0.5

			# Apply
			child.name = String(cur_name)
			cur_name += 1

			child.init((size / 2.0), lod + 1, last_player_pos, data[0])
			child.connect("tile_done_loading", self, "_on_child_tile_finished")

			children.call_deferred("add_child", child)


# Gets the distance of the center of the tile to the last known player location
func get_dist_to_player():
	# Get closest point within rectangle to circle
	var clamped_low = Vector3()
	var clamped_high = Vector3()
	
	var gtranslation = global_transform.origin # coordinates are hard in Godot... it HAS to be global_transform, weird behaviour otherwise!
	var origin = Vector2(gtranslation.x - size/2, gtranslation.z - size/2)
	var end = Vector2(gtranslation.x + size/2, gtranslation.z + size/2)
	
	# TODO: Height is hardcoded at 100-300, we need to get the actual height in the future!
	clamped_low.x = clamp(last_player_pos.x, origin.x, end.x)
	clamped_low.z = clamp(last_player_pos.z, origin.y, end.y)
	clamped_low.y = 100
	
	clamped_high = clamped_low
	clamped_high.y = 300
	
	return min(last_player_pos.distance_to(clamped_low), last_player_pos.distance_to(clamped_high))


# Recursively tries getting textures, starting at the current LOD, going down one LOD each step and cropping the result accordingly
func get_texture_recursive(tex_name, zoom, steps):
	var true_pos = get_true_position()
	
	var result = ServerConnection.getJson("/raster/%d.0/%d.0/%d.json"\
		% [-true_pos[0], true_pos[2], zoom])
		
	if result.has("Error"):
		# TODO: How to react to this? Currently no done_loading() is sent, so if there ever is an error, the client is
		# stuck here
		return
	
	# If there is no orthophoto at this zoom level, go back recursively
	if result.get(tex_name) == "None":
		return get_texture_recursive(tex_name, zoom - 1, steps + 1)
		
	var tex = CachingImageTexture.get(result.get(tex_name))
	
	# If we went back, get the cropped image
	if steps > 0:
		var size = 1.0 / pow(2, steps)
		var origin = get_offset_from_parents(steps)

		tex = CachingImageTexture.get_cropped(result.get(tex_name), origin, Vector2(size, size))
	
	return tex