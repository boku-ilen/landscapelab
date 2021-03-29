extends Resource
class_name VegetationLayerDefinition


export(int) var density_class_id = 1
export(float) var extent
export(Resource) var mesh


func get_renderer():
	var renderer = preload("res://Layers/Renderers/RasterVegetation/VegetationLayerRenderer.tscn").instance()
	
	renderer.density_class = Vegetation.density_classes[density_class_id]
	renderer.rows = extent * Vegetation.density_classes[density_class_id].density_per_m
	renderer.spacing = 1.0 / Vegetation.density_classes[density_class_id].density_per_m
	renderer.set_mesh(mesh)
	
	return renderer
