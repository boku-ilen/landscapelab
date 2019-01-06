tool
extends Spatial

#
# This is a general world tile which can hold multiple meshes or other information (modules).
# To increase the LOD, it can split into 4 new tiles.
# The tiles are controlled via the TileSpawner.
#

# Nodes
onready var this_scene = preload("res://Scenes/Testing/LOD/WorldTile.tscn")
onready var modules = get_node("Modules")
onready var children = get_node("Children")

# Variables
var size = 0
var lod
var heightmap
var texture
var image # TODO testing only

var has_split = false
var initialized = false

var split_all = false
var created = false
var player_bounding_radius = 3000
var near_factor = 2
var last_player_pos
var subdiv_mod = 1

var will_activate_at_pos

# [max lod, distance at which this max_lod starts applying, subdivision count modifier]
# Must be ordered desc
var max_lods = [ # TODO: Move subdivision count modifier to terrain
	[1, 8000, 1],
	[2, 5000, 1],
	[3, 2000, 1],
	[4, 800, 1],
	[5, 500, 1],
	[6, 300, 1],
	[7, 100, 1],
]
# Example: [2, 5000, 1] means that the maximum number of split()s within a 5000km radius (unless the player is within another, smaller radius)
# is 2 - one tile becomes 16. The subdivision count modifier is 1, so the default subdivision count is used.

# Modules that will be spawned, in the format: Start-LOD, module scenes
onready var module_scenes = [
	[0, [preload("res://Scenes/Testing/LOD/TerrainMesh.tscn")]]
#	[6, [preload("res://Scenes/Testing/LOD/Grass.tscn")]]
]
# Modules are always passed their position, size and lod-level 

func _ready():
	if initialized:
		# Spawn all required modules
		for mds in module_scenes:
			if mds[0] <= lod: # This tile's lod is equal to or greater than the module's requirement -> spawn it
				for md in mds[1]:
					modules.add_child(md.instance())
			else:
				break;

		if will_activate_at_pos:
			activate(will_activate_at_pos)
	else:
		print("Warning: Uninitialized WorldTile created")
	
	created = true

# Sets the parameters needed to actually create the tile (must be called before adding to the scene tree = must be called before _ready()!)
func init(s, hm, tex, img, lod_level, activate_pos=null, _subdiv_mod=1): # water map, ... will go here
	size = s
	heightmap = hm
	texture = tex
	image = img # TODO testing only
	lod = lod_level
	subdiv_mod = _subdiv_mod
	
	initialized = true
	
	will_activate_at_pos = activate_pos

# Removes all the higher LOD children
func clear_children():
	for child in children.get_children():
		child.free()

# Hides the mesh at this LOD - used when higher LOD children are shown instead
func set_modules_invisible():
	modules.visible = false

# Use the LOD at this tile (Make this mesh visible, and delete children modules) - for example, converge from 4 tiles to 1
func converge():
	modules.visible = true
	clear_children()
	has_split = false

# Called when the player is nearby - this makes the tile check whether it needs to split or converge, and do so if required.
func activate(player_pos):
	if !created: return
	
	last_player_pos = player_pos
	
	# Activate children with same pos
	for child in children.get_children():
		if child.has_method("activate"):
			child.activate(last_player_pos)
			
	var dist_to_player = get_dist_to_player()
	
	# Check if we need to split or converge
	if dist_to_player < max_lods[0][1]:
		var conv = false
		
		# Check whether this is a high LOD tile which needs to converge
		for lod_item in max_lods:
			if lod == lod_item[0] and dist_to_player > lod_item[1]:
				converge()
				conv = true
				
		if not conv:
			split(dist_to_player)
	else:
		converge()

# Move the tile in the world (used for offsetting)		
func move(delta):
	if !initialized: return
	
	translation += delta
	
# Increase the LOD on this tile (Split the tile into 4 smaller tiles)
func split(dist_to_player):
	if !initialized: return
	
	# Check what the max_lod should be given the distance
	var _max_lod = max_lods[0][1]
	var _subdiv_mod = 1
	
	for lod_item in max_lods:
		if dist_to_player < lod_item[1]:
			_max_lod = lod_item[0]
			_subdiv_mod = lod_item[2]
	
	if lod >= _max_lod: return # Don't split more often than max_lod
	
	if has_split:
		return
		
	has_split = true
	
	#ThreadPool.enqueue_task(ThreadPool.Task.new(self, "instantiate_children", [_subdiv_mod]))
	instantiate_children([_subdiv_mod])

# Here, the actual splitting happens - this function is run in a thread
func instantiate_children(data):
	var my_tex = image
	var current_tex_size = my_tex.get_size()
	var cur_name = 0
	
	children.visible = false
	
	# Add 4 children
	for x in range(0, 2):
		for y in range(0, 2):
			var xy_vec = Vector2(x, y)
			
			var child = this_scene.instance()
			
			# Set location
			var offset = Vector3(x - 0.5, 0, y - 0.5)  * size/2.0
			child.translation = offset.rotated(Vector3(0, 1, 0), PI) # Need to rotate in order to match up with get_rect image part

			# Get appropriate maps
			var rec_size = current_tex_size/2.0
			var new_tex = my_tex.get_rect(Rect2(rec_size * xy_vec, rec_size))

			var new_tex_texture = ImageTexture.new()
			new_tex_texture.create_from_image(new_tex, 8)

			# Apply
			child.name = String(cur_name)
			cur_name += 1

			child.init((size / 2.0), new_tex_texture, new_tex_texture, new_tex, lod + 1, last_player_pos, data[0])

			children.call_deferred("add_child", child)
			
	children.visible = true
	set_modules_invisible()
	
# Gets the distance of the center of the tile to the last known player location
func get_dist_to_player():
	# Get closest point within rectangle to circle
	var clamped_low = Vector3()
	var clamped_high = Vector3()
	
	var gtranslation = global_transform.origin # coordinates are hard in Godot... it HAS to be global_transform, weird behaviour otherwise!
	var origin = Vector2(gtranslation.x - size/2, gtranslation.z - size/2)
	var end = Vector2(gtranslation.x + size/2, gtranslation.z + size/2)
	
	clamped_low.x = clamp(last_player_pos.x, origin.x, end.x)
	clamped_low.z = clamp(last_player_pos.z, origin.y, end.y)
	clamped_low.y = 500 # Must be replaced with actual height!
	
	clamped_high = clamped_low
	clamped_high.y = 800
	
	return min(last_player_pos.distance_to(clamped_low), last_player_pos.distance_to(clamped_high))