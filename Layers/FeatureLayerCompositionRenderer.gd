extends LayerCompositionRenderer
class_name FeatureLayerCompositionRenderer


# Define variables for loading features
var features := []
var instances := {}
var radius = 6000.0
var max_features = 2000
# Some renderer might have more than a solitairy object per feature (e.g. connected
# objects), thus root nodes for applying/removing features have to be defined
#var root_nodes: Array[Node3D]


func _ready():
	super._ready()
	layer_composition.render_info.geo_feature_layer.feature_added.connect(_on_feature_added)
	layer_composition.render_info.geo_feature_layer.feature_removed.connect(_on_feature_removed)


func full_load():
	features = layer_composition.render_info.geo_feature_layer.get_features_near_position(
		float(center[0]), float(center[1]), radius, max_features)
	
	for feature in features:
		load_feature_instance(feature)


func adapt_load(_diff: Vector3):
	features = layer_composition.render_info.geo_feature_layer.get_features_near_position(
		float(center[0]) + position_manager.center_node.position.x,
		float(center[1]) - position_manager.center_node.position.z,
		radius, max_features
	)
	
	for feature in features:
		var fid = str(feature.get_id())
		if not instances.has(fid): 
			load_feature_instance(feature)
	
	call_deferred("apply_new_data")


func apply_new_data():
	var features_to_persist = {}
	
	for feature in features:
		var node_name = str(feature.get_id())
		
		if not has_node(node_name):
			# This feature is new
			apply_feature_instance(feature)
		
		features_to_persist[node_name] = feature
	
	for child in get_children():
		if not features_to_persist.has(child.name):
			# Remove features which should not be persisted
			child.free()
	
	super.apply_new_data()
	
	logger.info("Applied new feature data for %s" % [name])


func _on_feature_added(feature: GeoFeature):
	# Load the feature instance in a thread
	loading_thread.start(load_feature_instance.bind(feature))
	
	# Wait for the thread to finish before applying
	if loading_thread.is_started() and not loading_thread.is_alive():
		loading_thread.wait_to_finish()
	
	apply_feature_instance(feature)


func _on_feature_removed(feature: GeoFeature):
	if loading_thread.is_started() and not loading_thread.is_alive():
		loading_thread.wait_to_finish()
	
	remove_feature(feature)


# Might be necessary to be overwritten by inherited class
# Cannot be run in a thread
func remove_feature(feature: GeoFeature):
	if has_node(str(feature.get_id())):
		get_node(str(feature.get_id())).queue_free()
		instances.erase(str(feature.get_id()))


# To be implemented by inherited class
# Instantiate and initially configure (e.g. set position) of  the instance - run in a thread
# Append instances to dictionary
func load_feature_instance(feature: GeoFeature):
	pass


# Might be necessary to be overwritten by inherited class
# Apply feature to the main scene - cannot be run in a thread
func apply_feature_instance(feature: GeoFeature):
	if not feature.feature_changed.is_connected(_on_feature_changed):
		feature.feature_changed.connect(_on_feature_changed.bind(feature))
	if instances.has(str(feature.get_id())):
		add_child(instances[str(feature.get_id())])


func _on_feature_changed(feature: GeoFeature):
	_on_feature_removed(feature)
	_on_feature_added(feature)
