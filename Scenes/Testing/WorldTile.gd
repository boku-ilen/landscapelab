tool
extends Spatial

onready var meshes = get_node("Meshes")
onready var terrain = meshes.get_node("TerrainMesh")

var size = 0
var heightmap
var texture
var image # TODO testing only

var has_split = false
var initialized = false

var tile_scene = preload("res://Scenes/Testing/WorldTile.tscn")
	
func init(s, hm, tex, img): # water map, ... will go here
	size = s
	heightmap = hm
	texture = tex
	image = img # TODO testing only
	
	size = terrain.create(size, heightmap, texture)
	
	initialized = true
	
func clear_meshes():
	for child in meshes.get_children():
		child.queue_free()
	
func split():
	if has_split: return # Don't split twice
	if !initialized: return
	
	var my_tex = image
	var current_tex_size = my_tex.get_size()
	
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
			print(Rect2(rec_size * xy_vec, rec_size))
			
			var new_tex_texture = ImageTexture.new()
			new_tex_texture.create_from_image(new_tex, 8)
			
			# Apply
			var unique_name = randi() # TODO: not necessarily unique!
			child.name = String(unique_name)
			
			add_child(child)
			get_node(String(unique_name)).init((size / 2.0), new_tex_texture, new_tex_texture, new_tex)
	
	clear_meshes()
	
	has_split = true