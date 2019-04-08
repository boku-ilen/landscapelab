tool
extends Module

export var water_splat_id = 60

onready var water_mesh = get_node("MeshInstance")

var splat_result
var splatmap

func get_splat_data():
	var true_pos = tile.get_true_position()

	splat_result = ServerConnection.get_json("/%s/%d.0/%d.0/%d"\
		% ["vegetation", -true_pos[0], true_pos[2], tile.get_osm_zoom()])

func get_textures(data):
	get_splat_data()

	make_ready()

func set_splatmap():
	water_mesh.mesh = tile.create_tile_plane_mesh()
	tile.set_heightmap_params_for_obj(water_mesh.material_override)
	
	water_mesh.material_override.set_shader_param("splatmap", splatmap)
	water_mesh.material_override.set_shader_param("water_id", water_splat_id)
	
func _ready():
	translation.y = 400

	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "get_textures", []))

func _on_ready():
	if not splat_result or not splat_result.has("path_to_splatmap"):
		return
		
#	if not splat_result["ids"].has(water_splat_id):
#		return
	
	splatmap = CachingImageTexture.get(splat_result.get("path_to_splatmap"))
	
	set_splatmap()