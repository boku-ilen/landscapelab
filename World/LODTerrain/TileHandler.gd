extends Spatial

#
# This is the node that actually controls the whole LOD terrain.
# It spawns and handles tiles and also handles related tasks such as world shifting.
# In scenes with LOD terrain, this is what's placed in the scene tree.
#

var tile = preload("res://World/LODTerrain/WorldTile.tscn")
var GRIDSIZE = Settings.get_setting("lod", "level-0-tile-size") # Width and height of a tile (the biggest possible LOD terrain chunk, which then splits accordingly)

onready var player = get_tree().get_root().get_node("Main/PlayerViewport/Viewport/Controller")
onready var skycube = get_tree().get_root().get_node("Main/WorldEnvironment/SkyCube")
onready var light = get_tree().get_root().get_node("Main/WorldEnvironment/DirectionalLight")
onready var tiles = get_node("Tiles")
onready var assets = get_node("Assets")

# Every UPDATE_INTERVAL seconds, the world will check what tiles to spawn/activate
var UPDATE_INTERVAL = Settings.get_setting("lod", "update-interval-seconds")
var time_to_interval = 0

# When a player coordinate gets bigger than this, the world will be shifted to get the player back to the world origin
var shift_limit = Settings.get_setting("lod", "world-shift-distance")

var world_offset_x : int = 0
var world_offset_z : int = 0

# Radii for spawning and removing tiles
# Actually not really radii atm - currently rectangles
var TILE_RADIUS = Settings.get_setting("lod", "tile-spawn-radius")
var REMOVAL_RADIUS_SUMMAND = Settings.get_setting("lod", "tile-removal-check-radius-summand")

# Global options
export(bool) var update_terrain = true

func _ready():
	# Set world_offset to start values using Session
	# Spawn the bare minimum of tiles
	pass

func _input(event):
	if event.is_action_pressed("toggle_lod_update"):
		update_terrain = not update_terrain

func _process(delta):
	if not update_terrain: return
	
	time_to_interval += delta
	
	if time_to_interval >= UPDATE_INTERVAL: # Update
		time_to_interval -= UPDATE_INTERVAL
		
		var player_tile = get_tile_at_player()
		if player_tile == null: return
		
		# Loop through the entire rectangle (TILE_RADIUS + REMOVAL_RADIUS_SUMMAND)
		for x in range(player_tile.x - TILE_RADIUS - REMOVAL_RADIUS_SUMMAND, player_tile.x + TILE_RADIUS + 1 + REMOVAL_RADIUS_SUMMAND):
			for y in range(player_tile.y - TILE_RADIUS - REMOVAL_RADIUS_SUMMAND, player_tile.y + TILE_RADIUS + 1 + REMOVAL_RADIUS_SUMMAND):
				
				if (x in range(player_tile.x - TILE_RADIUS, player_tile.x + TILE_RADIUS + 1)
				and y in range(player_tile.y - TILE_RADIUS, player_tile.y + TILE_RADIUS + 1)):
					# We're in the smaller, spawning radius -> Spawn tiles in here which don't yet exist
					if not tiles.has_node("%d,%d" % [x, y]):
						# There is no tile here yet -> spawn the proper tile
						# TODO: Concurrency issues with offset position
						#ThreadPool.enqueue_task(ThreadPool.Task.new(self, "spawn_tile", [x, y]))
						spawn_tile([x, y])
				else:
					# We're outside the spawning radius -> Despawn any tiles left here
					if tiles.has_node("%d,%d" % [x, y]):
						tiles.get_node("%d,%d" % [x, y]).queue_free()
		
		# Activate 9 tiles closest to player
		if player:
			for x in range(player_tile.x - 2, player_tile.x + 3):
				for y in range(player_tile.y - 2, player_tile.y + 3):
					if tiles.has_node("%d,%d" % [x, y]):
						tiles.get_node("%d,%d" % [x, y]).activate(player.translation)
		
		# Offset world
		if player:
			shift_world()
		
	# Update skycube pos
	if player:
		skycube.reposition(player.translation, player.get_true_position())
		light.translation = player.translation

# Shift the world if the player exceeds the bounds, in order to prevent coordinates from getting too big (floating point issues)
func shift_world():
	var delta_vec = Vector3(0, 0, 0)
	
	# Check x coordinate
	if player.translation.x > shift_limit:
		delta_vec.x = -shift_limit
	elif player.translation.x < -shift_limit:
		delta_vec.x = shift_limit
		
	# (Height (y) probably doesn't matter, height differences won't be that big
	
	# Check z coordinate
	if player.translation.z > shift_limit:
		delta_vec.z = -shift_limit
	elif player.translation.z < -shift_limit:
		delta_vec.z = shift_limit
	
	# Apply
	player.shift(delta_vec)
	move_world(delta_vec)

# Spawn a tile at the given __tilegrid coordinate__ position
func spawn_tile(pos):
	var map_img = Image.new() # TODO testing only
	map_img.load("res://Scenes/Testing/LOD/test-tile.png")
#	var map = ImageTexture.new()
#	map.create_from_image(map_img, 8)
	
	var map = load("res://Scenes/Testing/LOD/test-tile.png")

	var tile_instance = tile.instance()
	tile_instance.name = "%d,%d" % [pos[0], pos[1]]
	tile_instance.translation = Vector3(pos[0] * -GRIDSIZE + world_offset_x, 0, pos[1] * -GRIDSIZE + world_offset_z)
	
	tile_instance.init(GRIDSIZE, map, map, map_img, 0)
	
	tiles.add_child(tile_instance)

# Move all world tiles by delta_vec (in true coordinates) and remember the total offset caused by using this function
func move_world(delta_vec):
	world_offset_x += delta_vec.x
	world_offset_z += delta_vec.z
	
	for child in tiles.get_children():
		child.move(delta_vec)
		
	for child in assets.get_children():
		child.translation += delta_vec

# Returns the grid coordinates of the tile at a certain absolute position (passed as an array for int accuracy)
func absolute_to_grid(var abs_pos):
	return Vector2(-round((abs_pos[0]) / int(GRIDSIZE)), -round((abs_pos[1]) / int(GRIDSIZE)))

# Get the tilegrid coordinates of the tile the player is currently standing on
func get_tile_at_player():
	if player != null:
		var true_player = player.get_true_position()
		var grid_vec = absolute_to_grid(true_player)
		return grid_vec
	else:
		return Vector2(0, 0)
		
func get_ground_coords(pos):
	var grid_pos = -1 * absolute_to_grid([world_offset_x + pos.x, world_offset_z + pos.z])
	
	if tiles.has_node("%d,%d" % [grid_pos.x, grid_pos.y]):
		return Vector3(pos.x, tiles.get_node("%d,%d" % [grid_pos.x, grid_pos.y]).get_height_at_position(pos), pos.z)
	else:
		return false

# Puts an instanced scene on the ground at a certain position using the heightmap of that tile
func put_on_ground(instanced_scene, pos):
	# TODO: The offset seems not to be handled completely properly, it seems slightly off sometimes
	var coords = get_ground_coords(pos)
	if coords:
		instanced_scene.translation = coords
		assets.add_child(instanced_scene)