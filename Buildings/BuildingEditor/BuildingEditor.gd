@tool
extends Node3D 

# Fake buttons as user input
@export_group("Controls")
@export var apply: bool:
	set(_none):
		if building_base != null:
			for child in building_base.get_children(): 
				child.queue_free()
				await(child.tree_exited)
		build()
@export var reset: bool:
	set(_none):
		building_base.queue_free()

# Export variables - parameters for building configuration
@export_group("Facade")
@export var wall_type: WALL_TYPE

@export_group("Roof")
@export var roof_type: ROOF_TYPE 
@export var roof_color: Color
@export var roof_material_0 := preload("res://Buildings/Components/Roofs/Resources/_RoofBarrel.tres")
@export var roof_material_1 := preload("res://Buildings/Components/Roofs/Resources/_RoofBarrel.tres")

static func polar_vertices(num_verts: int, radius):
	var angle: float = 2*PI / num_verts
	var vertices := []
	for i in range(num_verts):
		vertices.append(Vector2(sin(angle * (num_verts - i)) * radius, cos(angle * (num_verts - i)) * radius))
	return PackedVector2Array(vertices)
	
var preset_definitions = [
	PackedVector2Array([
		Vector2(-5, -5),
		Vector2(5, -5),
		Vector2(5, 5),
		Vector2(-5, 5),
		Vector2(-5, -5)
	]),
	# Built using polar vertices in enter tree
	PackedVector2Array([]),
	([
		Vector2(3, -8), Vector2(3, 8), Vector2(-3, 7), Vector2(-3, 4), Vector2(0, 4),
		Vector2(0, 1), Vector2(-3, 1), Vector2(-3, -2), Vector2(0, -2), Vector2(0, -5),
		Vector2(-3, -5), Vector2(-3, -8)
	]),
	PackedVector2Array([
		Vector2(-10, -5),
		Vector2(10, -5),
		Vector2(10, 5),
		Vector2(-10, 5),
		Vector2(-10, -5)
	]),
]

@export_group("Meta")
@export var height := 8.0: 
	set(new_height):
		height = new_height
		set_metadata("height", new_height)
@export var floors := 3
@export var footprint: PackedVector2Array = preset_definitions[FOOTPRINT_PRESETS.SQUARE]: 
	set(new_footprint): 
		footprint = new_footprint
		set_metadata("footprint", new_footprint)
@export var foot_print_presets: FOOTPRINT_PRESETS:
	set(new_preset):
		foot_print_presets = new_preset
		footprint = preset_definitions[new_preset]
		
		set_metadata("footprint", footprint)


# Internal variables
## Footprint
enum FOOTPRINT_PRESETS {
	SQUARE,
	CIRCULAR,
	E_SHAPED,
	RECTANGLE
}

## Roofs
enum ROOF_TYPE {
	SADDLE,
	POINTED,
	FLAT,
	FALLBACK
}

var roof_type_to_scene = {
	ROOF_TYPE.SADDLE: preload("res://Buildings/Components/Roofs/SaddleRoof.tscn"),
	ROOF_TYPE.POINTED: preload("res://Buildings/Components/Roofs/PointedRoof.tscn"),
	ROOF_TYPE.FLAT: preload("res://Buildings/Components/Roofs/FlatRoof.tscn"),
	ROOF_TYPE.FALLBACK: preload("res://Buildings/Components/Roofs/FlatRoof.tscn")
}

## Walls
enum WALL_TYPE {
	APARTMENTS,
	HOUSE,
	SHACK,
	INDUSTRIAL,
	OFFICE,
	SUPERMARKET,
	RETAIL_RESTAURANT,
	HISTORIC,
	RELIGIOUS,
	GREENHOUSE,
	CONCRETE,
	STONE,
	MEDITERRANEAN
}

## meta
var metadata = {
	"footprint": footprint,
	"height": height,
	"roof_height": floors * 2.5 - height, 
	"extent": 10 }


func set_metadata(key, val):
	metadata[key] = val
	metadata["roof_height"] = height - floors * 2.5


var building_base


func build() -> void:
	if building_base == null:
		building_base = load("res://Buildings/BuildingBase.tscn").instantiate()
		add_child(building_base)
	
	building_base.set_metadata(metadata)
	
	WallFactory.prepare_plain_walls(wall_type, metadata, building_base, floors)
	
	var roof
	
	roof = roof_type_to_scene[roof_type]
	if roof_type == ROOF_TYPE.SADDLE and footprint.size() > 5:
		print("Saddle roof requires 4-5 vertices")
		roof = roof_type_to_scene[ROOF_TYPE.FALLBACK]
	
	roof = roof.instantiate().with_data(0, {}, {}, metadata)
	roof.set_metadata(metadata)
	building_base.roof = roof
	roof.color = roof_color
	building_base.position = Vector3.ZERO
	
	building_base.build()
	if roof_material_1 != null and roof.roof_mesh.get_surface_override_material_count() > 1:
		roof.roof_mesh.set_surface_override_material(1, roof_material_1)
		roof.roof_mesh.material_override = null
	if roof_material_0 != null:
		roof.roof_mesh.set_surface_override_material(0, roof_material_0)
	
	for child in building_base.get_children():
		if "can_refine" in child and child.can_refine():
			child.refine()


func _enter_tree() -> void:
	_create_and_set_texture_arrays()
	preset_definitions[1] = polar_vertices(8, 10)


# To increase performance, create an array of textures which the same shader can
# read from
func _create_and_set_texture_arrays():
	var window_bundles = [
		preload("res://Resources/Textures/Buildings/window/Shutter/Shutter.tres"),
		preload("res://Resources/Textures/Buildings/window/DefaultWindow/DefaultWindow.tres"),
	]

	var shader = preload("res://Buildings/Components/Walls/PlainWalls.tscn").instantiate().material
		
	var wall_texture_arrays = TextureArrays.texture_arrays_from_wallres(WallFactory.wall_resources)
	shader.set_shader_parameter("texture_wall_albedo", wall_texture_arrays[0])
	shader.set_shader_parameter("texture_wall_normal", wall_texture_arrays[1])
	shader.set_shader_parameter("texture_wall_rme", wall_texture_arrays[2])
	
	# TODO: implement logic for multiple windows
	var albedo_images = []
	var normal_images = []
	var roughness_metallic_emission_images = []
	for bundle in window_bundles:
		var images = TextureArrays.formatted_images_from_textures([
				bundle.albedo_texture, 
				bundle.normal_texture, 
				bundle.bundled_texture])
		
		albedo_images.append(images[0])
		normal_images.append(images[1])
		roughness_metallic_emission_images.append(images[2])
	
	shader.set_shader_parameter("texture_window_albedo", TextureArrays.texture2Darrays_from_images(albedo_images))
	shader.set_shader_parameter("texture_window_normal", TextureArrays.texture2Darrays_from_images(normal_images))
	shader.set_shader_parameter("texture_window_rme", TextureArrays.texture2Darrays_from_images(roughness_metallic_emission_images))
