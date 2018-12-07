tool
extends Spatial

onready var meshes = get_node("Meshes")
onready var children = get_node("Children")
onready var terrain = meshes.get_node("TerrainMesh")

var size = 0
var lod
var heightmap
var texture
var image # TODO testing only

var has_split = false
var initialized = false

var split_all = false

var tile_scene = preload("res://Scenes/Testing/LOD/WorldTile.tscn")

var max_lod = 3

var activated = false
var created = false
var player_bounding_radius = 3000
var near_factor = 2
var last_player_pos

var will_activate_at_pos

func _ready():
#	create_thread.start(self, "create")
	create([])

func create(data):
	if initialized:
		terrain.call_deferred("create", size, heightmap, texture) # This makes things slightly better than calling it directly
		if will_activate_at_pos:
			activate(will_activate_at_pos)
	else:
		print("Warning: Uninitialized WorldTile created")
	
	created = true

func init(s, hm, tex, img, lod_level, activate_pos=null): # water map, ... will go here
	# Currently, this function receives img and tex paramters.
	# This is only for testing - in the future, this init function will get all textures from the middleware
		# using the position and size variables.
	
	# Of course, getting things from the middleware can take a bit, so this must not be blocking!
	# Therefore, it will spawn a thread to get everything it needs and then create the terrain there.
	# This means that the 'initialized' variable will have to be set there and checked whenever dealing with tiles - there
		# will be a good chance that tiles which are being dealt with aren't initialized yet!
	size = s
	heightmap = hm
	texture = tex
	image = img # TODO testing only
	lod = lod_level
	
	initialized = true
	
	will_activate_at_pos = activate_pos

# Removes all 
func clear_children():
	for child in children.get_children():
		child.queue_free()
		
func set_meshes_invisible():
	meshes.visible = false
	
func set_meshes_visible():
	# Make this mesh visible, and delete children meshes
	meshes.visible = true
	clear_children()
	has_split = false

func activate(player_pos):
	activated = true
	last_player_pos = player_pos
	
	for child in children.get_children():
		if child.has_method("activate"):
			child.activate(last_player_pos)
	
func _process(delta):
	if !activated: return
	
	# Check which tiles collide with player bounds
	if player_collide_with_bounds():
		split()
	else:
		set_meshes_visible()
		activated = false
	
# Split the tile into 4 smaller tiles with a higher LOD
func split():
	if lod == max_lod: return # Don't split more often than max_lod
	if !initialized: return
	
	if has_split:
		return
		
	has_split = true
	
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "instantiate_children", []))

# Here, the actual splitting happens - this function is run in a thread
func instantiate_children(data):
	var my_tex = image
	var current_tex_size = my_tex.get_size()
	
	children.visible = false
	
	# Add 4 children
	for x in range(0, 2):
		for y in range(0, 2):
			var xy_vec = Vector2(x, y)
			
			var child = tile_scene.instance()
			
			# Set location
			var offset = Vector3(x - 0.5, 0, y - 0.5)  * size/2.0
			child.translation = offset.rotated(Vector3(0, 1, 0), PI) # Need to rotate in order to match up with get_rect image part
			
			# Get appropriate maps
			var rec_size = current_tex_size/2.0
			var new_tex = my_tex.get_rect(Rect2(rec_size * xy_vec, rec_size))
			
			var new_tex_texture = ImageTexture.new()
			new_tex_texture.create_from_image(new_tex, 8)
			
			# Apply
			var unique_name = randi()*randi() # TODO: not necessarily unique!
			child.name = String(unique_name)
		
			child.init((size / 2.0), new_tex_texture, new_tex_texture, new_tex, lod + 1, last_player_pos)
			
			OS.delay_msec(100) # Apparently something is not thread safe - this is required!

			children.call_deferred("add_child", child)
			
	children.visible = true
	set_meshes_invisible()

# Returns true if the player bounds are within the tile's bounds
func player_collide_with_bounds(factor = 1):
	# Get closest point within rectangle to circle
	var clamped = Vector2()
	
	var gtranslation = global_transform.origin # coordinates are hard in Godot... it HAS to be global_transform, weird behaviour otherwise!
	var origin = Vector2(gtranslation.x - size/2, gtranslation.z - size/2)
	var end = Vector2(gtranslation.x + size/2, gtranslation.z + size/2)
	
	clamped.x = clamp(last_player_pos.x, origin.x, end.x)
	clamped.y = clamp(last_player_pos.z, origin.y, end.y)
	
	var dist = Vector2(last_player_pos.x, last_player_pos.z).distance_to(clamped)
	
	# Also check height - I think this is actually a cone at the moment, not a sphere
	var ydist = abs(gtranslation.y - last_player_pos.y + 700) # 700 must be replaced by the actual height
	var cur_radius = max(0, player_bounding_radius - ydist)
		
	return dist < cur_radius / factor