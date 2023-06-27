extends LayerCompositionRenderer
class_name FeatureLayerCompositionRendererMultiMesh


# Define variables for loading features
var mutex = Mutex.new()
var features := []
var instances := {}
var radius = 6000.0
var max_features = 2000
@onready var multimesh: MultiMesh = $MultiMeshInstance3D.multimesh

var remove_features := []
var load_features := []

signal feature_instance_removed(id: int)


func full_load():
	mutex.lock()
	features = layer_composition.render_info.geo_feature_layer.get_features_near_position(
		float(center[0]), float(center[1]), radius, max_features)
	
	for feature in features:
		instances[feature.get_id()] = load_feature_instance(feature)
	mutex.unlock()


func adapt_load(_diff: Vector3):
	mutex.lock()
	var new_features = layer_composition.render_info.geo_feature_layer.get_features_near_position(
		float(center[0]) + position_manager.center_node.position.x,
		float(center[1]) - position_manager.center_node.position.z,
		radius, max_features
	)
	
	var old_feature_ids = features.map(func(f): return f.get_id())
	load_features = new_features.filter(func(f): return not f.get_id() in old_feature_ids)
	features = new_features
	
	for feature in load_features:
		instances[feature.get_id()] = load_feature_instance(feature)
	
	mutex.unlock()
	
	call_deferred("apply_new_data")


# To be implemented by inherited class
# Apply loaded feature instances as transforms to the multimesh
func apply_new_data():
	super.apply_new_data()
	logger.info("Applied new feature data for %s" % [name])


# To be implemented by inherited class
# Instantiate and initially configure (e.g. set position) of  the instance - run in a thread
# Append instances to dictionary
func load_feature_instance(feature: GeoFeature) -> Node3D:
	return Node3D.new()


# To be implemented by inherited class
# AABBs have to be set manually in order to increase rendering performance
func build_aabb():
	return AABB()


func is_new_loading_required(position_diff: Vector3) -> bool:
	if Vector2(position_diff.x, position_diff.z).length_squared() >= pow(radius / 4.0, 2):
		return true
	
	return false
