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

var tile_scene = preload("res://Scenes/Testing/WorldTile.tscn")

var near_sphere_mult = 2
var max_lod = 3

var activated = false
var player_bounding_radius = 100
var last_player_pos
	
func init(s, hm, tex, img, lod_level): # water map, ... will go here
	size = s
	heightmap = hm
	texture = tex
	image = img # TODO testing only
	lod = lod_level
	
	size = terrain.create(size, heightmap, texture)
	
	initialized = true
	
func clear_meshes():
	for child in meshes.get_children():
		child.queue_free()
		
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
	
func split():
	if lod == max_lod: return # Don't split more often than max_lod
	if !initialized: return
	
	if has_split:
		return
	
	var my_tex = image
	var current_tex_size = my_tex.get_size()
	
	print("Splitting at LOD %d" % [lod])
	
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
			var unique_name = randi() # TODO: not necessarily unique!
			child.name = String(unique_name)
			
			children.add_child(child)
			children.get_node(String(unique_name)).init((size / 2.0), new_tex_texture, new_tex_texture, new_tex, lod + 1)
			children.get_node(String(unique_name)).activate(last_player_pos)
	
	set_meshes_invisible()
	
	has_split = true
	
func player_collide_with_bounds():
	# Get closest point within rectangle to circle
	var clamped = Vector2()
	
	var gtranslation = global_transform.origin # coordinates are hard in Godot... it HAS to be global_transform, weird behaviour otherwise!
	var origin = Vector2(gtranslation.x - size/2, gtranslation.z - size/2)
	var end = Vector2(gtranslation.x + size/2, gtranslation.z + size/2)
	
	clamped.x = clamp(last_player_pos.x, origin.x, end.x)
	clamped.y = clamp(last_player_pos.y, origin.y, end.y)
	
	var dist = last_player_pos.distance_to(clamped)
	
	return dist < player_bounding_radius