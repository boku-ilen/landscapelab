extends Module

#
# This module fetches the topomap for its tile, to be displayed on the minimap.
#

onready var mesh = get_node("MeshInstance")

var topo


func _ready():
	mesh.mesh = tile.create_tile_plane_mesh(false)
	
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "get_textures", []))


func _on_ready():
	if topo:
		mesh.material_override.albedo_texture = topo
		
	ready_to_be_displayed()


func get_topo():
	var response = tile.get_texture_result("raster")
	
	if response:
		if response.has("map"):
			topo = CachingImageTexture.get(response.get("map"))


func get_textures(data):
	get_topo()
	
	make_ready()
