extends Button


var geo_transform = GeoTransform.new()

@export var geo_layer_renderers: Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pressed.connect(import_points_from_webgis)
	geo_transform.set_transform(4326, 3857)


func import_points_from_webgis():
	# Create an HTTP request node and connect its completion signal.
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_http_request_completed)

	# Perform a GET request. The URL below returns JSON as of writing.
	var error = http_request.request("http://127.0.0.1:8000/api/entries/biopv-test")
	if error != OK:
		push_error("An error occurred in the HTTP request.")


func _http_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	var parent_node = Node2D.new()
	parent_node.name = "WebGISResult"
	
	if geo_layer_renderers.has_node("WebGISResult"):
		geo_layer_renderers.get_node("WebGISResult").free()
	
	for survey_entry in response:
		var point_wg84 = survey_entry["location_entry__geom"]["geometry"]["coordinates"]
		var point_webm = geo_transform.transform_coordinates(Vector3(point_wg84[0], 0.0, point_wg84[1]))
		var vec2_webm = Vector2(point_webm.x, point_webm.z)
		var local_vector = vec2_webm - geo_layer_renderers.center
		local_vector *= Vector2(1, -1)
		
		var marker_icon
		
		if survey_entry["field_data"]["Schönheit des Ortes"][0] == "9":
			marker_icon = preload("res://Resources/Icons/LabTable/symbol_yes.png")
		else:
			marker_icon = preload("res://Resources/Icons/LabTable/symbol_no.png")
		
		parent_node.add_child(get_new_marker(
			local_vector,
			marker_icon
		))
	
	geo_layer_renderers.add_child(parent_node)


func get_new_marker(position: Vector2, marker_icon): 
	var marker = Sprite2D.new()
	marker.set_texture(marker_icon)
	marker.set_position(position)
	marker.set_scale(Vector2.ONE * 0.4)
	
	return marker
