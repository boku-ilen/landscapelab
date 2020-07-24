extends Spatial
class_name BaseTiles

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

# Radii for spawning and removing tiles
# Actually not really radii atm - currently rectangles
var TILE_RADIUS = Settings.get_setting("lod", "tile-spawn-radius")
var REMOVAL_RADIUS_SUMMAND = Settings.get_setting("lod", "tile-removal-check-radius-summand")

# Get's injected from a node above
var center_node: Spatial
var position_manager: Node

# Global options
export(bool) var update_terrain = true


func _ready():
	# TODO: Spawn the bare minimum of tiles
	
	UISignal.connect("tile_update_toggle", self, "_toggle_tile_update")
	GlobalSignal.connect("reset_tiles", self, "reset")


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
	
	if time_to_interval >= UPDATE_INTERVAL and center_node != null: # Update
		time_to_interval -= UPDATE_INTERVAL
		
		var center_tile = get_tile_at_center()
		if center_tile == null: return
		
		# Loop through the entire rectangle (TILE_RADIUS + REMOVAL_RADIUS_SUMMAND)
		for x in range(center_tile.x - TILE_RADIUS - REMOVAL_RADIUS_SUMMAND, center_tile.x + TILE_RADIUS + 1 + REMOVAL_RADIUS_SUMMAND):
			for y in range(center_tile.y - TILE_RADIUS - REMOVAL_RADIUS_SUMMAND, center_tile.y + TILE_RADIUS + 1 + REMOVAL_RADIUS_SUMMAND):
				
				if (x in range(center_tile.x - TILE_RADIUS, center_tile.x + TILE_RADIUS + 1)
				and y in range(center_tile.y - TILE_RADIUS, center_tile.y + TILE_RADIUS + 1)):
					# We're in the smaller, spawning radius -> Spawn tiles in here which don't yet exist
					if not tiles.has_node("%d,%d" % [x, y]):
						# There is no tile here yet -> spawn the proper tile
						spawn_tile([x, y])
				else:
					# We're outside the spawning radius -> Despawn any tiles left here
					if tiles.has_node("%d,%d" % [x, y]):
						tiles.get_node("%d,%d" % [x, y]).delete()
		
		# Activate 9 tiles closest to player
		for x in range(center_tile.x - 2, center_tile.x + 3):
			for y in range(center_tile.y - 2, center_tile.y + 3):
				if tiles.has_node("%d,%d" % [x, y]):
					tiles.get_node("%d,%d" % [x, y]).activate()


# Spawn a tile at the given __tilegrid coordinate__ position
func spawn_tile(pos):
	var tile_instance = tile.instance()
	#tile_instance.center_node = center_node
	#tile_instance.position_manager = position_manager
	tile_instance.name = "%d,%d" % [pos[0], pos[1]]
	tile_instance.translation = Offset.to_engine_coordinates([pos[0] * GRIDSIZE + GRIDSIZE/2, 0, pos[1] * GRIDSIZE + GRIDSIZE/2])
	
	tile_instance.init(GRIDSIZE, 0, position_manager, center_node)
	
	# These root tiles need to react to world shifting since they are
	#  responsible for the global position; their children are simply relative
	#  to them
	tile_instance.add_to_group("SpatialShifting")
	
	tiles.add_child(tile_instance)


# Returns the grid coordinates of the tile at a certain absolute position (passed as an array for int accuracy)
func absolute_to_grid(abs_pos: Vector3):
	return Vector2(round((abs_pos[0] - GRIDSIZE/2) / GRIDSIZE), round((abs_pos[2] - GRIDSIZE/2) / GRIDSIZE))


# Get the tilegrid coordinates of the tile the player is currently standing on
func get_tile_at_center():
	return absolute_to_grid(center_node.translation)


# Returns the top-level tile (no tile parent) which is at the given position, or null
#  if there is no tile for that position.
func get_tile_at_position(position: Vector3):
	var grid_pos = absolute_to_grid(position)
	
	if tiles.has_node("%d,%d" % [grid_pos.x, grid_pos.y]):
		return tiles.get_node("%d,%d" % [grid_pos.x, grid_pos.y])
	
	return null


func get_ground_coords(pos):
	var grid_pos = absolute_to_grid(position_manager.to_world_coordinates(pos))
	
	if tiles.has_node("%d,%d" % [grid_pos.x, grid_pos.y]):
		return tiles.get_node("%d,%d" % [grid_pos.x, grid_pos.y]).get_position_on_ground(pos)
	else:
		return pos


func get_ground_normal(pos):
	var grid_pos = absolute_to_grid(position_manager.to_world_coordinates(pos))
	
	if tiles.has_node("%d,%d" % [grid_pos.x, grid_pos.y]):
		return tiles.get_node("%d,%d" % [grid_pos.x, grid_pos.y]).get_normal_on_ground(pos)
	else:
		return Vector3.UP


# Puts an instanced scene on the ground at a certain position using the heightmap of that tile
func put_on_ground(instanced_scene, pos):
	# TODO: The offset seems not to be handled completely properly, it seems slightly off sometimes
	var coords = get_ground_coords(pos)
	if coords:
		instanced_scene.translation = coords
		assets.add_child(instanced_scene)
