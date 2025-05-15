extends Resource
class_name ColorRamps


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
			offsets = PackedFloat32Array(util.rangef(0., 1., 1. / _colors.size()))
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

static var gradients = {
	"viridis": ColorRamp.new(
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
	).as_gradient(),
	"wind_speed": ColorRamp.new(
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
	).as_gradient(),
	"mako": ColorRamp.new(
		ColorRamp.OffsetInit.EQUIDISTANT,
		PackedColorArray([
			Color(0.0431, 0.0157, 0.0196),   # (11, 4, 5)
			Color(0.1216, 0.0706, 0.1451),   # between (11,4,5) and (51,35,69)
			Color(0.2000, 0.1373, 0.2706),   # (51, 35, 69)
			Color(0.2353, 0.1765, 0.3490),   # between (51,35,69) and (63,54,109)
			Color(0.2471, 0.2118, 0.4275),   # (63, 54, 109)
			Color(0.2549, 0.2667, 0.5333),   # (65, 68, 136)
			Color(0.2314, 0.3647, 0.5961),   # between (65,68,136) and (53,115,161)
			Color(0.2078, 0.4510, 0.6314),   # (53, 115, 161)
			Color(0.2039, 0.5843, 0.6627),   # (52, 149, 169)
			Color(0.2353, 0.6353, 0.6706),   # between (52,149,169) and (68,174,173)
			Color(0.2667, 0.6824, 0.6784),   # (68, 174, 173)
			Color(0.2588, 0.7255, 0.6784),   # (66, 185, 173)
			Color(0.4510, 0.8039, 0.7333),   # between (66,185,173) and (164,224,187)
			Color(0.6431, 0.8784, 0.7333),   # (164, 224, 187)
			Color(0.7529, 0.9137, 0.8000),   # (192, 233, 204)
			Color(0.8706, 0.9608, 0.8980)    # (222, 245, 229)
		]),
		Gradient.GRADIENT_INTERPOLATE_LINEAR
	).as_gradient()
}
static var viridis = gradients["viridis"]
static var wind_speed = gradients["wind_speed"]
static var mako = gradients["mako"]
