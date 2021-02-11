extends Resource
class_name VegetationLayerDefinition


export(float) var min_plant_size
export(float) var max_plant_size
export(float) var extent
export(float) var density
export(Resource) var mesh


func get_renderer():
	var renderer = preload("res://Layers/Renderers/RasterVegetation/VegetationLayerRenderer.tscn").instance()
	
	renderer.min_size = min_plant_size
	renderer.max_size = max_plant_size
	renderer.rows = extent * density
	renderer.spacing = 1.0 / density
	renderer.set_mesh(mesh)
	
	return renderer
