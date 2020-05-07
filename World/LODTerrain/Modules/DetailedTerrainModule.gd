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
	if tile.lod > 2:
		viewport.size = Vector2(128, 128)
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

	splatmap = tile.get_geoimage("land-use", 6)
	
	# Set the basic parameters
	mesh.material_override.set_shader_param("water_splat_id", WATER_SPLAT_ID)
	mesh.material_override.set_shader_param("splat", splatmap.get_image_texture())
	mesh.material_override.set_shader_param("detail_start_dist", DETAIL_START_DIST)
	mesh.material_override.set_shader_param("tex_factor", DETAIL_SCALE)
	mesh.material_override.set_shader_param("is_detailed", true)
	
	# Get the most common splat IDs and use them to set the detail textures
	var splat_ids = splatmap.get_most_common(8)
	
	# Map splatmap IDs to rows in these spritesheets
	var id_row_map_tex = Vegetation.get_id_row_map_texture(splat_ids)
	mesh.material_override.set_shader_param("id_to_row", id_row_map_tex)
	
	# Load spritesheets
	var phytocoenosis = Vegetation.get_phytocoenosis_array_for_ids(splat_ids)
	
	var detail_albedo_sheet = Vegetation.get_ground_sheet_texture(phytocoenosis, "albedo")
	var detail_normal_sheet = Vegetation.get_ground_sheet_texture(phytocoenosis, "normal")
	var detail_depth_sheet = Vegetation.get_ground_sheet_texture(phytocoenosis, "displacement")
	
	mesh.material_override.set_shader_param("detail_albedo_sheet", detail_albedo_sheet)
	mesh.material_override.set_shader_param("detail_normal_sheet", detail_normal_sheet)
	mesh.material_override.set_shader_param("detail_depth_sheet", detail_depth_sheet)
	
	return true
