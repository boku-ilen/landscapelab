extends Node2D
class_name GeoLayerRenderer


# Offset to use as the center position
var center := Vector2.ZERO
var viewport_size := Vector2.ONE * 100
var zoom := Vector2.ONE
var radius := 1000

var global_to_local_transform
var local_to_global_transform


func _ready():
	global_to_local_transform = GeoTransform.new()
	global_to_local_transform.set_transform(31287, 3857)
	
	local_to_global_transform = GeoTransform.new()
	local_to_global_transform.set_transform(3857, 31287)


# Overload with the functionality to load new data, but not use (visualize) it yet. Run in a thread,
#  so watch out for thread safety!
func load_new_data():
	Thread.set_thread_safety_checks_enabled(false)
	pass


# Overload to return a string with statistics and information about the current state of this
# renderer
func get_debug_info() -> String:
	return ""


# Overload with applying and visualizing the data. Not run in a thread.
func apply_new_data():
	pass


func global_vector3_to_local_vector2(vector: Vector3) -> Vector2:
	# Geo Vector3 assumes -z as forward, here we need +z as forward
	vector.z = -vector.z
	
	var transformed = global_to_local_transform.transform_coordinates(vector)
	
	transformed.x -= center.x
	transformed.z = center.y - transformed.z
	
	return Vector2(transformed.x, transformed.z)


func global_vector2_to_local_vector2(vector: Vector2) -> Vector2:
	return global_vector3_to_local_vector2(Vector3(vector.x, 0.0, vector.y))


func get_center_global():
	var transformed = local_to_global_transform.transform_coordinates(Vector3(center.x, 0.0, center.y))
	return Vector2(transformed.x, transformed.z)


func set_metadata(new_center: Vector2, new_viewport_size: Vector2, new_zoom: Vector2):
	center = new_center
	viewport_size = new_viewport_size
	zoom = new_zoom
	# The maximum radius is at the corners => get the diagonale divided by 2
	radius = sqrt(pow(new_viewport_size.x / new_zoom.x, 2) 
				+ pow(new_viewport_size.y / new_zoom.y, 2)) / 2


# Reload the data within this layer
# Not threaded! Should only be called as a response to user input, otherwise use load_new_data and
# apply_new_data threaded as intended
func refresh():
	load_new_data()
	apply_new_data()
