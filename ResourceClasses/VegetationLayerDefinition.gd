extends Resource
class_name VegetationLayerDefinition


export(Vegetation.DensityClass) var density_class
export(float) var extent
export(Resource) var mesh


func get_renderer():
	var renderer = preload("res://Layers/Renderers/RasterVegetation/VegetationLayerRenderer.tscn").instance()
	
	renderer.density_class = density_class
	renderer.rows = extent * Vegetation.max_densities[density_class]
	renderer.spacing = 1.0 / Vegetation.max_densities[density_class]
	renderer.set_mesh(mesh)
	
	return renderer
