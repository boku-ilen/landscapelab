extends PathFollowCurve
class_name RoadLane

const LANE_TYPE_TO_NAME: Dictionary = {
	-1:		"Unknown",
	0: 		"Car Lane",
	1: 		"Bike Lane",
	2: 		"Pedestrian Lane",
	3: 		"Parking Lane",
	4: 		"Multi-purpose Lane",
	5: 		"Bike and Pedestrian Lane",
}


# Road info
var lane_type: int = -1

# Road path info
@export var road_height: float = 0.2
@export var width_extension_bottom := 0.0
@export var lower_into_ground := 0.0
@export var dynamic_width := true
@export var render_lid := true
@export var write_into_height_overlay := false
@export var write_into_texture_overlay := true
@export var render_3d := true

var road_width: float = 2.0
var road_offset: float = 0.0
var percentage_from = 0.0
var percentage_to = 100.0
var is_bridge = false

var road_curve: Curve3D

# Parent road instance
var road_instance: RoadInstance


var custom_road_width: float = 0.0
var custom_road_offset: float = 0.0
var custom_road_height: float = 0.0
var custom_percentage_from = 0.0
var custom_percentage_to = 0.0


func _ready():
	LIDOverlay.updated.emit()
	visibility_changed.connect(func(): LIDOverlay.updated.emit())


func update_road_lane() -> void:
	var total_road_width = road_width + custom_road_width
	var total_road_height = road_height + custom_road_height
	var total_road_offset = road_offset + custom_road_offset
	var total_percentage_from = percentage_from + custom_percentage_from
	var total_percentage_to = percentage_to + custom_percentage_to
	
	var half_width = (total_road_width) / 2.0
	
	if dynamic_width:
		var polygon: PackedVector2Array = [
			Vector2(-half_width + width_extension_bottom, total_road_height),
			Vector2(half_width, total_road_height),
			Vector2(half_width + width_extension_bottom, -lower_into_ground),
			Vector2(-half_width, -lower_into_ground)
		]
		
		# Set polygon
		$RoadLanePolygon.polygon = polygon
	
	# Set underlying PathFollowCurve values
	self.curve_to_follow = road_curve
	self.offset = total_road_offset + (sign(total_road_offset) * half_width)
	self.start = total_percentage_from / 100.0
	self.end = total_percentage_to / 100.0
	self.update_curve()
	
	# Set shader variables
	$RoadLanePolygon.material.set_shader_parameter("width", total_road_width)
	$RoadLanePolygon.material.set_shader_parameter("height", total_road_height)
	
	if render_lid:
		$RoadLanePolygon.layers = pow(2, 16) # LID
	else:
		$RoadLanePolygon.material.set_shader_parameter("render_lid", false)
	
	if write_into_texture_overlay:
		# Write into texture overlay (terrain decal)
		$RoadLanePolygon.layers += pow(2, 15)
	
	if render_3d:
		# Write into detail mesh (normal 3D object rendering)
		$RoadLanePolygon.layers += pow(2, 2)
	
	if write_into_height_overlay:
		$RoadLanePolygon.layers += pow(2, 17)


func reset_custom_values() -> void:
	custom_road_width = 0.0
	custom_road_offset = 0.0
	custom_road_height = 0.0
	custom_percentage_from = 0.0
	custom_percentage_to = 0.0


func get_info() -> Array:
	return [
		RoadInfoData.new("Lane Type", LANE_TYPE_TO_NAME[lane_type], "", false),
		RoadInfoData.new("Width", road_width, "Meter", true, self, "custom_road_width"),
		RoadInfoData.new("Offset", road_offset, "Meter", true, self, "custom_road_offset"),
		RoadInfoData.new("Percentage from", snapped(percentage_from, 0.01), "%%", true, self, "custom_percentage_from"),
		RoadInfoData.new("Percentage to", snapped(percentage_from, 0.01), "%%", true, self, "custom_percentage_to")
	]
