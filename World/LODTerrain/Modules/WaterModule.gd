tool
extends Module

onready var water_mesh = get_node("MeshInstance")

var splat_result
var splatmap
var dhm

var WATER_SPLAT_ID = Settings.get_setting("water", "water-splat-id")

func get_splat_data():
	var true_pos = tile.get_true_position()

	splat_result = ServerConnection.get_json("/%s/%d.0/%d.0/%d"\
		% ["vegetation", -true_pos[0], true_pos[2], tile.get_osm_zoom()])
		
	dhm = tile.get_texture_recursive("dhm", tile.get_osm_zoom(), 0)

func get_textures(data):
	get_splat_data()

	make_ready()

func set_splatmap():
	water_mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(water_mesh.material_override)
	
	water_mesh.material_override.set_shader_param("splatmap", splatmap)
	water_mesh.material_override.set_shader_param("water_id", WATER_SPLAT_ID)
	water_mesh.material_override.set_shader_param("heightmap", dhm)
	
func _ready():
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "get_textures", []))

func _on_ready():
	if not splat_result or not splat_result.has("path_to_splatmap"):
		return
		
	if not splat_result["ids"].has(WATER_SPLAT_ID):
		return
	
	splatmap = CachingImageTexture.get(splat_result.get("path_to_splatmap"))
	
	set_splatmap()