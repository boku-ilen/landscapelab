extends Spatial

#
# This is the node that actually controls the whole LOD terrain.
# It spawns and handles tiles and also handles related tasks such as world shifting.
# In scenes with LOD terrain, this is what's placed in the scene tree.
#

var tile = preload("res://World/LODTerrain/WorldTile/WorldTile.tscn")
# Width and height of a tile (the biggest possible LOD terrain chunk, which then splits accordingly)
var GRIDSIZE = Settings.get_setting("lod", "level-0-tile-size") 

onready var tiles = get_node("Tiles")
onready var assets = get_node("Assets")

# Every UPDATE_INTERVAL seconds, the world will check what tiles to spawn/activate
var UPDATE_INTERVAL = Settings.get_setting("lod", "update-interval-seconds")
var time_to_interval = 0

# When a player coordinate gets bigger than this, the world will be shifted to get the player back to the world origin
var shift_limit = Settings.get_setting("lod", "world-shift-distance")

# Radii for spawning and removing tiles
# Actually not really radii atm - currently rectangles
var TILE_RADIUS = Settings.get_setting("lod", "tile-spawn-radius")
var REMOVAL_RADIUS_SUMMAND = Settings.get_setting("lod", "tile-removal-check-radius-summand")

# Global options
export(bool) var update_terrain = true


func _ready():
	# TODO: Spawn the bare minimum of tiles
	
	Offset.connect("shift_world", self, "move_world")
	GlobalSignal.connect("tile_update_toggle", self, "_toggle_tile_update")
	GlobalSignal.connect("reset_tiles", self, "reset")
	
	WorldPosition.set_handler(self)


# Toggle whether the tiles are splitting (increasing their LOD) and fetched/deleted based on the position
func _toggle_tile_update(update):
	update_terrain = update
	

# Resets by deleting all tiles
func reset():
	for child in tiles.get_children():
		child.delete()


func _process(delta):
	if not update_terrain: return
	
	time_to_interval += delta
	
	if time_to_interval >= UPDATE_INTERVAL: # Update
		time_to_interval -= UPDATE_INTERVAL
		
		var player_tile = get_tile_at_player()
		if player_tile == null: return
		
		var player_pos = PlayerInfo.get_engine_player_position()
		
		# Loop through the entire rectangle (TILE_RADIUS + REMOVAL_RADIUS_SUMMAND)
		for x in range(player_tile.x - TILE_RADIUS - REMOVAL_RADIUS_SUMMAND, player_tile.x + TILE_RADIUS + 1 + REMOVAL_RADIUS_SUMMAND):
			for y in range(player_tile.y - TILE_RADIUS - REMOVAL_RADIUS_SUMMAND, player_tile.y + TILE_RADIUS + 1 + REMOVAL_RADIUS_SUMMAND):
				
				if (x in range(player_tile.x - TILE_RADIUS, player_tile.x + TILE_RADIUS + 1)
				and y in range(player_tile.y - TILE_RADIUS, player_tile.y + TILE_RADIUS + 1)):
					# We're in the smaller, spawning radius -> Spawn tiles in here which don't yet exist
					if not tiles.has_node("%d,%d" % [x, y]):
						# There is no tile here yet -> spawn the proper tile
						spawn_tile([x, y])
				else:
					# We're outside the spawning radius -> Despawn any tiles left here
					if tiles.has_node("%d,%d" % [x, y]):
						tiles.get_node("%d,%d" % [x, y]).delete()
		
		# Activate 9 tiles closest to player
		for x in range(player_tile.x - 2, player_tile.x + 3):
			for y in range(player_tile.y - 2, player_tile.y + 3):
				if tiles.has_node("%d,%d" % [x, y]):
					tiles.get_node("%d,%d" % [x, y]).activate(player_pos)
		
		# Offset world
		check_for_world_shift()


# Shift the world if the player exceeds the bounds, in order to prevent coordinates from getting too big (floating point issues)
func check_for_world_shift():
	var delta_vec = Vector3(0, 0, 0)
	var player_pos = PlayerInfo.get_engine_player_position()
	
	# Check x, z coordinates
	delta_vec.x = -shift_limit * floor(player_pos.x / shift_limit)
	delta_vec.z = -shift_limit * floor(player_pos.z / shift_limit)
	# (Height (y) probably doesn't matter, height differences won't be that big
	
	# Apply
	if delta_vec != Vector3(0, 0, 0):
		Offset.emit_signal("shift_world", delta_vec.x, delta_vec.z)


# Spawn a tile at the given __tilegrid coordinate__ position
func spawn_tile(pos):
	var tile_instance = tile.instance()
	tile_instance.name = "%d,%d" % [pos[0], pos[1]]
	tile_instance.translation = Offset.to_engine_coordinates([pos[0] * GRIDSIZE + GRIDSIZE/2, 0, pos[1] * GRIDSIZE + GRIDSIZE/2])
	
	tile_instance.init(GRIDSIZE, 0)
	
	tiles.add_child(tile_instance)


# Move all world tiles by delta_vec (in true coordinates) and remember the total offset caused by using this function
func move_world(delta_x, delta_z):
	var delta_vec = Vector3(delta_x, 0, delta_z)
	
	for child in tiles.get_children():
		child.move(delta_vec)
		
	for child in assets.get_children():
		child.translation += delta_vec


# Returns the grid coordinates of the tile at a certain absolute position (passed as an array for int accuracy)
func absolute_to_grid(abs_pos):
	return Vector2(round((abs_pos[0] - GRIDSIZE/2) / GRIDSIZE), round((abs_pos[2] - GRIDSIZE/2) / GRIDSIZE))


# Get the tilegrid coordinates of the tile the player is currently standing on
func get_tile_at_player():
	var true_player = PlayerInfo.get_true_player_position()
	var grid_vec = absolute_to_grid(true_player)

	return grid_vec


func get_ground_coords(pos):
	var grid_pos = absolute_to_grid(Offset.to_world_coordinates(pos))
	
	if tiles.has_node("%d,%d" % [grid_pos.x, grid_pos.y]):
		return tiles.get_node("%d,%d" % [grid_pos.x, grid_pos.y]).get_position_on_ground(pos)
	else:
		return pos


# Puts an instanced scene on the ground at a certain position using the heightmap of that tile
func put_on_ground(instanced_scene, pos):
	# TODO: The offset seems not to be handled completely properly, it seems slightly off sometimes
	var coords = get_ground_coords(pos)
	if coords:
		instanced_scene.translation = coords
		assets.add_child(instanced_scene)
