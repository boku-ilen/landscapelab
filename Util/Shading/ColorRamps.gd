extends Resource
class_name Colors


static func create_legend(
		color_ramp_id: String, 
		vertical:=true, 
		min_size:=Vector2(50,200), 
		min_size_per_bucket:=Vector2(1,1)) -> BoxContainer:
	var box: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new() as BoxContainer
	box.custom_minimum_size = min_size
	box.add_theme_constant_override("separation", 0)
	for color in color_ramps[color_ramp_id]:
		var color_bucket = ColorRect.new()
		box.add_child(color_bucket)
		color_bucket.size_flags_vertical = Control.SIZE_EXPAND_FILL
		color_bucket.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		color_bucket.custom_minimum_size = min_size_per_bucket
		color_bucket.color = color
	
	return box


const color_ramps = {
	"Viridis": [
		Color(0.2667, 0.0039, 0.3294),
		Color(0.2824, 0.1020, 0.4235),
		Color(0.2784, 0.1843, 0.4902),
		Color(0.2549, 0.2667, 0.5294),
		Color(0.2235, 0.3373, 0.5490),
		Color(0.1922, 0.4078, 0.5569),
		Color(0.1647, 0.4706, 0.5569),
		Color(0.1373, 0.5333, 0.5569),
		Color(0.1216, 0.5961, 0.5451),
		Color(0.1333, 0.6588, 0.5176),
		Color(0.2078, 0.7176, 0.4745),
		Color(0.3294, 0.7725, 0.4078),
		Color(0.4784, 0.8196, 0.3176),
		Color(0.6471, 0.8588, 0.2118),
		Color(0.8235, 0.8863, 0.1059),
		Color(0.9922, 0.9059, 0.1451),
	],
	"WindSpeed": [
		Color.WHITE_SMOKE,
		Color(0.792, 0.8, 0.851), 
		Color(0.659, 0.694, 0.89), 
		Color(0.522, 0.584, 0.925), 
		Color(0.376, 0.463, 0.929), 
		Color(0.251, 0.373, 1),
		Color.NAVY_BLUE
	]
}
