extends LayerCompositionRenderer
class_name FeatureLayerCompositionRenderer

#
# This class is intended to be used as a base class for all feature-based rendering
# (points, lines, polygons). The basic workflow uppon loading:
# 1. get the features in within the loading radius in the new extent
# 2. manipulate instanced features:
# 	a. preserve features that have been loaded previously and should not be freed
# 	b. delete features that are no longer within the radius
# 	c. create newly and previously unloaded features
#
# The function load_feature_instance has to be defined by the inherited class.
#
# Furthermore, it handles manual adding/deleting of features via signals.
#


# Define variables for loading features
var mutex = Mutex.new()

var features := []

var remove_features := []
var load_features := []

class FeatureChange:
	enum ChangeType { ADD, REMOVE }
	
	var change_type: ChangeType
	var feature: GeoFeature
	
	func _init(new_change_type, new_feature):
		change_type = new_change_type
		feature = new_feature

var change_queue: Array[FeatureChange] = []

var instances := {}
@export var radius := 6000.0
@export var max_features := 2000

signal feature_instance_removed(id: int)

var is_first_load := true


func _ready():
	super._ready()
	layer_composition.render_info.geo_feature_layer.feature_added.connect(_on_feature_added, CONNECT_DEFERRED)
	layer_composition.render_info.geo_feature_layer.feature_removed.connect(_on_feature_removed, CONNECT_DEFERRED)


func full_load():
	# Delete all previous features
	features.clear()
	for child in get_children():
		# FIXME: Workaround for ConnectedObjectRenderer, would need some kind of override or extra parent node
		if not child.name == "Connections":
			child.free()
	
	adapt_load(Vector3.ZERO)


func adapt_load(_diff: Vector3):
	super.adapt_load(_diff)
	
	var new_features = layer_composition.render_info.geo_feature_layer.get_features_near_position(
		float(center[0]) + position_manager.center_node.position.x,
		float(center[1]) - position_manager.center_node.position.z,
		radius, max_features
	)
	
	# FIXME: might be a potential thread vulnerability
	var old_feature_ids = features.map(func(f): return f.get_id())
	var new_feature_ids = new_features.map(func(f): return f.get_id())
	
	remove_features = features.filter(func(f): return not f.get_id() in new_feature_ids)
	load_features = new_features.filter(func(f): return not f.get_id() in old_feature_ids)
	
	features = new_features
	
	mutex.lock()
	for feature in load_features:
		instances[feature.get_id()] = load_feature_instance(feature)
	mutex.unlock()
	
	# FIXME: Workaround for not calling apply here after first load
	if not is_first_load:
		call_deferred("apply_new_data")
	else:
		is_first_load = false


func apply_new_data():
	mutex.lock()
	
	for feature in remove_features:
		remove_feature(feature.get_id())
	
	for feature in load_features:
		apply_feature_instance(feature)
	
	mutex.unlock()
	
	super.apply_new_data()
	
	logger.info("Applied new feature data for %s" % [name])


func refine_load():
	super.refine_load()
	
	if change_queue.size() > 0:
		var changeset = change_queue.pop_front()
		var feature = changeset.feature
		
		if changeset.change_type == FeatureChange.ChangeType.ADD:
			instances[feature.get_id()] = load_feature_instance(feature)
			features.append(feature)
			apply_feature_instance.call_deferred(feature)
		elif changeset.change_type == FeatureChange.ChangeType.REMOVE:
			remove_feature.call_deferred(feature.get_id())


func _on_feature_added(feature: GeoFeature):
	change_queue.push_back(FeatureChange.new(FeatureChange.ChangeType.ADD, feature))


func _on_feature_removed(feature: GeoFeature):
	change_queue.push_back(FeatureChange.new(FeatureChange.ChangeType.REMOVE, feature))


# Might be necessary to be overwritten by inherited class
# Cannot be run in a thread
func remove_feature(feature_id: int):
	if instances.has(feature_id):
		instances.erase(feature_id)
	if has_node(str(feature_id)):
		# a simple queue_free() can cause crashes when multithreading! 
		var node = get_node(str(feature_id))
		remove_child(node)
		node.free()
	
	feature_instance_removed.emit(feature_id)


# To be implemented by inherited class
# Instantiate and initially configure (e.g. set position) of  the instance - run in a thread
# Append instances to dictionary
func load_feature_instance(feature: GeoFeature) -> Node3D:
	return Node3D.new()


# Might be necessary to overwrite by inherited class
# Apply feature to the main scene - not run in a thread
func apply_feature_instance(feature: GeoFeature):
	if not feature.feature_changed.is_connected(_on_feature_changed):
		feature.feature_changed.connect(
			_on_feature_changed.bind(feature), CONNECT_DEFERRED)
	
	mutex.lock()
	if instances.has(feature.get_id()) and instances[feature.get_id()] != null:
		if has_node(str(feature.get_id())):
			logger.warn("Feature with ID {} was already a child, this should not happen.
					Removing it before adding a new one.".format([feature.get_id()], "{}"))
			remove_child(get_node(str(feature.get_id())))
		
		add_child(instances[feature.get_id()])
	else:
		logger.error("No feature instance was created for ID: {}".
			format([feature.get_id()], "{}"))
		return
	mutex.unlock()


func _on_feature_changed(feature: GeoFeature):
	_on_feature_removed(feature)
	_on_feature_added(feature)


func is_new_loading_required(position_diff: Vector3) -> bool:
	if Vector2(position_diff.x, position_diff.z).length_squared() >= pow(radius / 4.0, 2):
		return true
	
	return false
