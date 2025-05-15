class_name WallFactory
extends Resource


# It is important to reference a wall_resource and not loading another 
const fallback_wall_id := 1
const wall_resources = [
	# "apartments": 0
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "house": 1
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "shack": 2
	preload("res://Resources/Textures/Buildings/PlainWallResources/Shack.tres"),
	# "industrial": 3
	preload("res://Resources/Textures/Buildings/PlainWallResources/Industrial.tres"),
	# "office": 4
	preload("res://Resources/Textures/Buildings/PlainWallResources/Office.tres"),
	# "supermarket": 5
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "retail_restaurant": 6
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "historic": 7
	preload("res://Resources/Textures/Buildings/PlainWallResources/BrickHouse.tres"),
	# "religious": 8
	preload("res://Resources/Textures/Buildings/PlainWallResources/BrickHouse.tres"),
	# "greenhouse": 9
	preload("res://Resources/Textures/Buildings/PlainWallResources/House.tres"),
	# "concrete": 10
	preload("res://Resources/Textures/Buildings/PlainWallResources/Concrete.tres"),
	# "stone": 11
	preload("res://Resources/Textures/Buildings/PlainWallResources/BrickHouse.tres"),
	# "mediterranean": 12
	preload("res://Resources/Textures/Buildings/PlainWallResources/PanterlleriaHouse.tres"),
]
const window_bundles = [
	preload("res://Resources/Textures/Buildings/window/Shutter/Shutter.tres"),
	preload("res://Resources/Textures/Buildings/window/Window/Window.tres"),
	preload("res://Resources/Textures/Buildings/window/GridWindows/2x2Window.tres"),
	preload("res://Resources/Textures/Buildings/window/OldWindow/OldWindow.tres"),
	preload("res://Resources/Textures/Buildings/window/SmallVertical/SmallVerticalWindow.tres")
]

const plinth_height_factor = 0.025

enum FLOOR_FLAG {
	BASEMENT = 0b1,
	GROUND = 0b10,
	MIDDLE = 0b100,
	TOP = 0b1000
}

static func prepare_plain_walls(
		building_type: int, 
		building_metadata: Dictionary,
		building: Node3D, 
		num_floors: int,
		walls_scene: PackedScene = preload("res://Buildings/Components/Walls/PlainWalls.tscn"),
		walls_material: ShaderMaterial = null):
	
	var walls_node = walls_scene.instantiate()
	if walls_material != null:
		walls_node.material = walls_material
	
	var building_type_id = building_type \
		if building_type in range(wall_resources.size()) \
		else fallback_wall_id
	
	var walls_resource: PlainWallResource = wall_resources[building_type_id]
	
	# Random facade texture
	var random_gen = RandomNumberGenerator.new()
	random_gen.seed = hash(building_metadata["footprint"])

	var wall_color = Color.WHITE_SMOKE
	var random = random_gen.randf_range(0, 1)
	
	var color_num := 0
	var summed_weight := 0.
	for weight in walls_resource.random_color_weights:
		summed_weight += weight
		if random <= summed_weight: break
		color_num += 1
	
	wall_color = walls_resource.random_colors[color_num]
	
	# Indexing textures from texture2Darray
	# Each bundle consists of: basement, ground, mid, top
	# => building_type 1 basement => 1 * 4 + 3
	# => building_type 3 top => 3 * 4 + 3
	var get_cellar_index = func(building_id): return int(building_id) * 4 + 0
	var get_ground_index = func(building_id): return int(building_id) * 4 + 1
	var get_mid_index = func(building_id): return int(building_id) * 4 + 2
	var get_top_index = func(building_id): return int(building_id) * 4 + 3
	
	# Random texture scale
	var random_tex_scale = Vector2(random_gen.randf_range(0.85, 1.15), 1)
	
	# Add a cellar
	var cellar = walls_node.duplicate()
	cellar.set_color(Color.WHITE_SMOKE)
	# Add an additional height to the cellar which acts as "plinth" scaled with the extent
	cellar.height += plinth_height_factor * min(20., building_metadata["extent"])
	cellar.set_wall_texture_index(get_cellar_index.call(building_type_id))
	
	# Cellars usually do not have windows
	cellar.set_window_texture_index(-1)
	cellar.texture_scale = walls_resource.basement_texture.texture_scale * random_tex_scale
	cellar.random_90_rotation_rate = walls_resource.random_90_rotation_rate
	if walls_resource.apply_colors & FLOOR_FLAG.BASEMENT:
		cellar.set_color(wall_color)
	building.add_child(cellar)
	
	# TODO: add window indexing
	# Add ground floor
	num_floors -= 1
	var ground_floor = walls_node.duplicate()
	ground_floor.set_wall_texture_index(get_ground_index.call(building_type_id))
	ground_floor.set_window_texture_index(walls_resource.ground_window_id)
	ground_floor.set_color(Color.WHITE_SMOKE)
	ground_floor.texture_scale = walls_resource.ground_texture.texture_scale * random_tex_scale
	ground_floor.random_90_rotation_rate = walls_resource.random_90_rotation_rate
	if walls_resource.apply_colors & FLOOR_FLAG.GROUND: 
		ground_floor.set_color(wall_color)
		
	building.add_child(ground_floor)
	
	# Add mid floors (only if there is are enough floors left)
	if num_floors >= 1:
		if num_floors >= 2:
			for i in range(num_floors - 2):
				var walls = walls_node.duplicate()
				walls.set_wall_texture_index(get_mid_index.call(building_type_id))
				walls.set_window_texture_index(walls_resource.middle_window_id)
				walls.set_color(Color.WHITE_SMOKE)
				walls.texture_scale = walls_resource.middle_texture.texture_scale * random_tex_scale
				walls.random_90_rotation_rate = walls_resource.random_90_rotation_rate
				if walls_resource.apply_colors & FLOOR_FLAG.MIDDLE:
					walls.set_color(wall_color)
				building.add_child(walls)
		
		# Add top floor
		var top_floor = walls_node.duplicate()
		top_floor.set_wall_texture_index(get_top_index.call(building_type_id))
		top_floor.set_window_texture_index(walls_resource.top_window_id)
		top_floor.set_color(Color.WHITE_SMOKE)
		top_floor.texture_scale = walls_resource.top_texture.texture_scale * random_tex_scale
		top_floor.random_90_rotation_rate = walls_resource.random_90_rotation_rate
		if walls_resource.apply_colors & FLOOR_FLAG.TOP:
			top_floor.set_color(wall_color)
		building.add_child(top_floor)


static func prepare_pillars(building_metadata: Dictionary, building: Node3D, num_floors: int):
	var walls_scene = load("res://Buildings/Components/Walls/Pillars.tscn").instantiate()
	walls_scene.ground_height_at_center = building_metadata["engine_center_position"].y
	walls_scene.floors = num_floors
	building.add_child(walls_scene)
