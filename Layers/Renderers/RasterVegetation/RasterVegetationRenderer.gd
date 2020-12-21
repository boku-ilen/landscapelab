extends LayerRenderer

onready var renderer = get_node("Renderer")


# Called when the node enters the scene tree for the first time.
func _ready():
	# Shorthand
	var ri = layer.render_info
	
	renderer.min_size = ri.min_plant_size
	renderer.max_size = ri.max_plant_size
	renderer.rows = ri.extent * ri.density
	renderer.spacing = 1.0 / ri.density
	
	renderer.update_textures(ri.height_layer, ri.landuse_layer, 420776.711, 453197.501)
