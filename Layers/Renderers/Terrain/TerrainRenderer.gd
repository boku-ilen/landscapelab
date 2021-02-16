extends LayerRenderer


var update_threads = []
var done = false


func _ready():
	# Create a loading thread for each LOD child
	for lod in get_children():
		lod.height_layer = layer.render_info.height_layer.clone()
		lod.texture_layer = layer.render_info.texture_layer.clone()
		var new_thread = Thread.new()
		new_thread.start(self, "update_lods", [lod])
		update_threads.append(new_thread)


func _process(delta):
	# TODO: Currently this is called anytime any LOD is ready. This is great for the first
	#  loading, since nearby data is available very quickly. However, when e.g. shifting,
	#  we only want to update once _everything_ is ready!
	if done:
		for lod in get_children():
			lod.call_deferred("apply_textures")
		
		done = false


# Continuously update the LOD of the node in data[0]
# To be called in a thread
func update_lods(data):
	# TODO: Move this position out, pass it from the World node down to here
	var pos_x = 420776.711
	var pos_y = 453197.501
	
	while true:
		data[0].position_x = pos_x
		data[0].position_y = pos_y
		
		data[0].build()
		
		done = true
		
		# TODO: Instead of waiting a fixed amount of time, wait until we need to shift
		#  or load new data for some other reason
		OS.delay_msec(1000)
