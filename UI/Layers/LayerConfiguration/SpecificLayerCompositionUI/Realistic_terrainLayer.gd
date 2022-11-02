extends SpecificLayerCompositionUI


func assign_specific_layer_info(layer_composition):
	if layer_composition.render_info == null:
		layer_composition.render_info = LayerComposition.RealisticTerrainRenderInfo.new()
	
	var texture_layer = $RightBox/GeodataChooserTexture.get_geo_layer(true)
	var height_layer = $RightBox/GeodataChooserHeight.get_geo_layer(true)
	var sheight_layer = $RightBox/GeodataChooserSurfaceHeight.get_geo_layer(true)
	var landuse_layer = $RightBox/GeodataChooserLandUse.get_geo_layer(true)

	if !validate(texture_layer) or !validate(height_layer):
		print_warning("Texture2D- or height-layer is invalid!")
		return
	
	layer_composition.render_info.height_layer = height_layer.clone()
	layer_composition.render_info.texture_layer = texture_layer.clone()
	layer_composition.render_info.surface_height_layer = sheight_layer.clone()
	layer_composition.render_info.landuse_layer = landuse_layer.clone()


func init_specific_layer_info(layer_composition: LayerComposition):
	$RightBox/GeodataChooserHeight.init_from_layer(
		layer_composition.render_info.height_layer)
	$RightBox/GeodataChooserTexture.init_from_layer(
		layer_composition.render_info.texture_layer)
	$RightBox/GeodataChooserSurfaceHeight.init_from_layer(
		layer_composition.render_info.surface_height_layer)
	$RightBox/GeodataChooserLandUse.init_from_layer(
		layer_composition.render_info.landuse_layer)
