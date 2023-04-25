extends LayerCompositionRenderer
class_name FeatureLayerCompositionRenderer


var features
# Some renderer might have more than a solitairy object per feature (e.g. connected
# objects), thus root nodes for applying/removing features have to be defined
#var root_nodes: Array[Node3D]

# Additional logic for when a thread has already been started is necessary to
# avoid crashes
var is_loading: bool
var feature_add_queue = []
var feature_remove_queue = []


func _ready():
	super._ready()
	layer_composition.render_info.geo_feature_layer.feature_added.connect(_on_feature_added)
	layer_composition.render_info.geo_feature_layer.feature_removed.connect(_on_feature_removed)


func apply_new_data():
	var features_to_persist = {}
	
	for feature in features:
		var node_name = var_to_str(feature.get_id())
		
		if not has_node(node_name):
			# This feature is new
			apply_new_feature(feature)
		
		features_to_persist[node_name] = feature
	
	for child in get_children():
		if not features_to_persist.has(child.name):
			# Remove features which should not be persisted
			child.free()
		else:
			# Move the feature according to the new offset
			update_instantiated_feature(features_to_persist[child.name])
	
	is_loading = false
	
	# Apply queues
	for feature in feature_add_queue:
		if not has_node(var_to_str(feature.get_id())):
			apply_new_feature(feature)
	
	for feature in feature_remove_queue:
		remove_feature(feature)
	
	feature_add_queue.clear()
	feature_remove_queue.clear()
	
	super.apply_new_data()
	
	logger.info("Applied new feature data for %s" % [name])


func _on_feature_added(feature):
	if not is_loading:
		apply_new_feature(feature)
	else:
		# TODO: We could add a temporary object here for immediate feedback
		feature_add_queue.append(feature)
		
	feature.feature_changed.connect(update_instantiated_feature.bind(feature))


func _on_feature_removed(feature):
	if not is_loading:
		remove_feature(feature)
	else:
		# TODO: We could potentially already remove_at the feature here as well since we check whether
		#  it exists when removing later; needs to be tested
		feature_remove_queue.append(feature)


func remove_feature(feature):
	if has_node(var_to_str(feature.get_id())):
		get_node(var_to_str(feature.get_id())).queue_free()


# To be implemented by inherited class
# Simply instantiate and apply initial configuration
# Do not set variables (e.g. position) here
func apply_new_feature(feature):
	pass


# To be implemented by inherited class
# Update the instantiated feature, i.e. set variables (e.g. position) 
func update_instantiated_feature(feature):
	pass
