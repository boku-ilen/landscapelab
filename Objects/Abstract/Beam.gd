@tool
extends Node3D


@export var color: Color
@export var default_radius := 250.0
@export var min_radius := 50.0

var feature: GeoFeature:
	set(new_feature):
		feature = new_feature
		
		var radius_in_feature = feature.get_attribute("radius")
		
		if radius_in_feature != "":
			var new_radius = max(min_radius, float(radius_in_feature))
			set_radius(new_radius)
	
	get():
		return feature


func _ready():
	$Light.light_color = color
	$Marker.set_instance_shader_parameter("color", color)
	
	if not feature:
		set_radius(default_radius)


func set_radius(new_radius):
	$Light.omni_range = new_radius * 1.5
	$Light.position.y = new_radius
	
	$Marker.scale = Vector3.ONE * new_radius / 100.0
