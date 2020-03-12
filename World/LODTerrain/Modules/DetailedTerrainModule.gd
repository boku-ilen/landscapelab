extends "res://World/LODTerrain/Modules/TerrainModule.gd"

#
# This module extends the TerrainModule to replace the orthophoto with detailed
# ground textures based on the vegetation splatmap when the player gets close.
# 
# In addition, everything in the 'Overlay' render layer is projected onto the
# terrain using the OverlayTextureViewport.
#

var splat_result
var splatmap

var vegetations = []
var albedos = []
var normals = []
var ids = []

var vegetation_max = Settings.get_setting("herbage", "max-vegetations-per-tile")

var WATER_SPLAT_ID = Settings.get_setting("water", "water-splat-id")
var DETAIL_START_DIST = Settings.get_setting("herbage", "detail-texture-start-distance")
var DETAIL_SCALE = Settings.get_setting("herbage", "detail-texture-scale")


func init(data=null):
	.init(data)
	
	# Setup the overlay texture camera
	var viewport = get_node("OverlayTextureViewport")
	var camera = viewport.get_node("Pivot/Camera")
	
	camera.size = tile.size
	
	# TODO: Scale this more nicely
	if tile.lod > 5:
		viewport.size = Vector2(1024, 1024)
		get_node("MeshInstance").material_override.set_shader_param("has_overlay", true)
	elif tile.lod > 4:
		viewport.size = Vector2(256, 256)
		get_node("MeshInstance").material_override.set_shader_param("has_overlay", true)
	
	GlobalSignal.connect("overlay_updated", self, "_render_overlay")


func _ready():
	# Render the overlay data that's currently here
	_render_overlay()


# Since the overlay camera doesn't need to render every frame, this function
# is provided to render a new frame. It is called e.g. when the 'overlay_updated'
# signal is emitted.
func _render_overlay():
	var viewport = get_node("OverlayTextureViewport")
	viewport.render_target_update_mode = viewport.UPDATE_ONCE


func get_textures(tile, mesh):
	var super_textures = .get_textures(tile, mesh)
	var new_textures = get_vegetation_data(tile, mesh)
	
	return super_textures and new_textures


func get_vegetation_data(tile, mesh):
	var true_pos = tile.get_true_position()

	splatmap = tile.get_geoimage("sentinel-invekos-bytes", "tif", 6)
	
	# Set the basic parameters
	mesh.material_override.set_shader_param("water_splat_id", WATER_SPLAT_ID)
	mesh.material_override.set_shader_param("splat", splatmap.get_image_texture())
	mesh.material_override.set_shader_param("detail_start_dist", DETAIL_START_DIST)
	mesh.material_override.set_shader_param("tex_factor", DETAIL_SCALE)
	
	# Get the most common splat IDs and use them to set the detail textures
	var splat_ids = splatmap.get_most_common(vegetation_max)
	
	# Add as many vegetations as available on server / possible on client
	for i in range(0, vegetation_max):
		# We use the layer 1 here, but the layer doesn't matter - the detail textures are the
		# same on all layers (since all layers are on the same ground)
		var result = ServerConnection.get_json("/vegetation/%d/1" % [splat_ids[i]])
		
		if result:
			var albedo = CachingImageTexture.get(result.get("albedo_path"))
			var normal = CachingImageTexture.get(result.get("normal_path"))
			
			if albedo:
				mesh.material_override.set_shader_param("vegetation_tex%d" % [i + 1], albedo)
				mesh.material_override.set_shader_param("vegetation_id%d" % [i + 1], splat_ids[i])
				
				if normal:
					mesh.material_override.set_shader_param("vegetation_normal%d" % [i + 1], normal)
	
	return true
