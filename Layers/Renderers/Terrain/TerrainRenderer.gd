extends LayerRenderer


var update_thread = Thread.new()
var done = false


func _ready():
	update_thread.start(self, "update_lods")


func _process(delta):
	if done:
		# Now that all data is loaded, apply all new tetures at once
		for lod in get_children():
			lod.call_deferred("apply_textures")
		
		done = false


func update_lods(data):
	# TODO: Move this position out, pass it from the World node down to here
	var pos_x = 420776.711
	var pos_y = 453197.501
	
	while true:
		for lod in get_children():
			lod.position_x = pos_x
			lod.position_y = pos_y
		
			lod.height_layer = layer.render_info.height_layer
			lod.texture_layer = layer.render_info.texture_layer
			
			lod.build()
		
		done = true
