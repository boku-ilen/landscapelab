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
var size
var lod : int
var heightmap
var texture
var image # TODO testing only

var has_split = false
var initialized = false

var split_all = false
var created = false
var last_player_pos
var subdiv_mod = 1

var subdiv = 16
var size_with_skirt

var will_activate_at_pos

var player_bounding_radius = Settings.get_setting("lod", "player-bounding-radius")
var max_lods = Settings.get_setting("lod", "distances")
var module_path = Settings.get_setting("lod", "module-path")
var module_scenes = Settings.get_setting("lod", "modules")

func _ready():
	if initialized:
		# Spawn all required modules
		var index = 0
		
		for mds in module_scenes:
			if index <= lod: # This tile's lod is equal to or greater than the module's requirement -> spawn it
				for md in mds:
					modules.add_child(load(module_path + md).instance() as Module)
			else:
				break; # We arrived at the higher LODs, which means we can stop now
				
			index += 1

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
	
# Creates a PlaneMesh which corresponds to the current size and subdivision
func create_tile_plane_mesh():
	var mesh = PlaneMesh.new()
	
	# We add 2 to subdiv and increase the size by the added squares for the skirt around the mesh (which fills gaps where things don't match up)
	size_with_skirt = size + (2.0/(subdiv + 1.0)) * size
	mesh.size = Vector2(size_with_skirt, size_with_skirt)
	
	mesh.subdivide_depth = subdiv + 2 # Add 1 left and 1 right for the skirt
	mesh.subdivide_width = subdiv + 2
	
	return mesh
	
func set_heightmap_params_for_obj(obj):
	obj.set_shader_param("heightmap", heightmap)
	obj.set_shader_param("subdiv", subdiv)
	obj.set_shader_param("size", size_with_skirt)
	obj.set_shader_param("size_without_skirt", size)

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
	
# Returns the height on the tile at a certain position (the y coordinate of the passed vector is ignored)
# TODO: Maybe change into get_position_on_ground and return whole position for ease of use?
func get_height_at_position(var pos):
	var img = heightmap.get_data()
	img.lock()
	var pos_scaled = (Vector2(pos.x, pos.z) - Vector2(translation.x, translation.z) + Vector2(size / 2, size / 2)) / size
	var pix_pos = pos_scaled * img.get_size()
	
	# Clamp to max values
	pix_pos.x = clamp(pix_pos.x, 0, img.get_size().x - 1)
	pix_pos.y = clamp(pix_pos.y, 0, img.get_size().y - 1)
	
	var height = img.get_pixel(pix_pos.x, pix_pos.y).g * 500 # TODO: Centralize height range and use here
	img.unlock()	

	return height

# Called when the player is nearby - this makes the tile check whether it needs to split or converge, and do so if required.
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
	
# Increase the LOD on this tile (Split the tile into 4 smaller tiles)
func split(dist_to_player):
	if !initialized: return
	
	if lod >= max_lods.size(): return # Don't split if we're already at the last max_lods item
	
	if has_split:
		return
		
	has_split = true
	
	#ThreadPool.enqueue_task(ThreadPool.Task.new(self, "instantiate_children", [_subdiv_mod]))
	instantiate_children([1])

# Here, the actual splitting happens - this function can be run in a thread
func instantiate_children(data):
	var my_tex = image
	var current_tex_size = my_tex.get_size()
	var cur_name = 0 # The children are simply named from 0 to 3
	
	# Hide children while they're being built
	children.visible = false
	
	# Add 4 children
	for x in range(0, 2):
		for y in range(0, 2):
			var xy_vec = Vector2(x, y)
			
			var child = this_scene.instance()
			
			# Set location
			var offset = Vector3(x - 0.5, 0, y - 0.5)  * size/2.0
			child.translation = offset#.rotated(Vector3(0, 1, 0), PI) # Need to rotate in order to match up with get_rect image part

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
	
	# Now that we're done, make the children visible instead of the old tile
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
	clamped_low.y = 100 # Must be replaced with actual height!
	
	clamped_high = clamped_low
	clamped_high.y = 300
	
	return min(last_player_pos.distance_to(clamped_low), last_player_pos.distance_to(clamped_high))