extends Resource
class_name ColorRamps


static func create_smybology(gradient: Gradient, ticks_at: Array[float] = [], vertical:=true) -> TextureRect:
	var tex_rect = TextureRect.new()
	var texture = GradientTexture2D.new()
	texture.gradient = gradient
	tex_rect.texture = texture
	
	texture.fill_to = Vector2(0, 1) if vertical else Vector2(1, 0)
	tex_rect.flip_h = true
	tex_rect.flip_v = true
	
	return tex_rect


class ColorRamp:
	var offsets: PackedFloat32Array
	var colors: PackedColorArray
	var interpolation: Gradient.InterpolationMode
	
	enum OffsetInit {
		EQUIDISTANT,
		RELATIVE
	}
	
	func _init(_offset_init: OffsetInit, _colors: PackedColorArray, _interpolation: Gradient.InterpolationMode, _offsets: Variant = null):
		if _offset_init == OffsetInit.EQUIDISTANT:
			offsets = util.rangef(0., 1., 1. / colors.size())
		elif _offset_init == OffsetInit.RELATIVE:
			assert(_offsets is PackedFloat32Array and _offsets.size() == _colors.size())
			offsets = _offsets
		
		colors = _colors
		interpolation = _interpolation
	
	func as_gradient():
		var gradient = Gradient.new()
		gradient.set_colors(colors)
		gradient.set_offsets(offsets)
		gradient.set_interpolation_mode(interpolation)
		
		return gradient


static var viridis = ColorRamp.new(
	ColorRamp.OffsetInit.EQUIDISTANT,
	PackedColorArray([
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
	]),
	Gradient.GRADIENT_INTERPOLATE_LINEAR
).as_gradient().duplicate()

static var wind_speed = ColorRamp.new(
	ColorRamp.OffsetInit.RELATIVE,
	PackedColorArray([
		Color(0.745, 0.643, 0.333),
		Color(0.890, 0.937, 0.941),
		Color(0.522, 0.769, 0.871),
		Color(0.765, 0.812, 0.976),
		Color(0.898, 0.686, 1.000)
	]),
	Gradient.GRADIENT_INTERPOLATE_LINEAR,
	PackedFloat32Array([
		0.,
		0.45,
		0.75,
		0.965,
		1.
	])
).as_gradient().duplicate()
