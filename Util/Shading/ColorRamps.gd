extends Resource
class_name Colors


static func create_smybology(
		colors: PackedColorArray,
		values: PackedFloat32Array,
		vertical:=true, 
		interpolation_mode: Gradient.InterpolationMode = Gradient.GRADIENT_INTERPOLATE_LINEAR) -> TextureRect:
	var tex_rect = TextureRect.new()
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	texture.gradient = gradient
	tex_rect.texture = texture
	
	assert(values.size() == colors.size())
	
	var max = Array(values).max()
	if max > 1.:
		values = PackedFloat32Array(Array(values).map(func(v): return v / max))
		
	gradient.set_colors(colors)
	gradient.set_offsets(values)
	
	gradient.interpolation_mode = interpolation_mode
	texture.fill_to = Vector2(0, 1) if vertical else Vector2(1, 0)
	if vertical: gradient.reverse()
	
	return tex_rect


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
		Color(0.745, 0.643, 0.333),
		Color(0.890, 0.937, 0.941),
		Color(0.522, 0.769, 0.871),
		Color(0.765, 0.812, 0.976),
		Color(0.898, 0.686, 1.000)
	]
}
