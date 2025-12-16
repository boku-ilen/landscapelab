@tool
extends CompositorEffect
class_name PostProcessShader


var context := "LENS_FLARE"

var downsample_shader_file = load("res://addons/compositor-lens-flare/downsample.glsl")
var lens_shader_file = load("res://addons/compositor-lens-flare/lens.glsl")
var blur_shader_file = load("res://addons/compositor-lens-flare/gaussian_blur.glsl")
var overlay_shader_file = load("res://addons/compositor-lens-flare/overlay.glsl")

@export_group("Guassian Blur", "gaussian_blur_")
@export_range(5.0, 50.0) var gaussian_blur_size: float = 32.0

@export var lens_flare_color_ramp: Texture2D

var downsample_shader: RID
var downsample_pipeline: RID

var lens_shader: RID
var lens_pipeline: RID

var blur_shader: RID
var blur_pipeline: RID

var overlay_shader: RID
var overlay_pipeline: RID

var rd: RenderingDevice

var mutex: Mutex = Mutex.new()
var shader_is_dirty: bool = true

@export_tool_button("Reload", "Callable") var reload_action = reload

# Called when this resource is constructed.
func _init():
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	RenderingServer.call_on_render_thread(_initialize_compute)


# System notifications, we want to react on the notification that
# alerts us we are about to be destroyed.
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if lens_shader.is_valid():
			# Freeing our shader will also free any dependents such as the pipeline!
			rd.free_rid(lens_shader)


func reload():
	if lens_shader.is_valid():
		# Freeing our shader will also free any dependents such as the pipeline!
		rd.free_rid(lens_shader)
	if downsample_shader.is_valid():
		rd.free_rid(downsample_shader)
	
	RenderingServer.call_on_render_thread(_initialize_compute)


func _initialize_compute():
	rd = RenderingServer.get_rendering_device()
	
	#compile_shader(lens_shader_file, lens_shader, lens_pipeline)
	#compile_shader(downsample_shader_file, downsample_shader, downsample_pipeline)
	
	var lens_shader_spirv: RDShaderSPIRV = lens_shader_file.get_spirv()

	if lens_shader_spirv.compile_error_compute != "":
		push_error(lens_shader_spirv.compile_error_compute)
		return false

	lens_shader = rd.shader_create_from_spirv(lens_shader_spirv)
	if not lens_shader.is_valid():
		return false

	lens_pipeline = rd.compute_pipeline_create(lens_shader)
	
	var downsample_shader_spirv: RDShaderSPIRV = downsample_shader_file.get_spirv()

	if downsample_shader_spirv.compile_error_compute != "":
		push_error(downsample_shader_spirv.compile_error_compute)
		return false

	downsample_shader = rd.shader_create_from_spirv(downsample_shader_spirv)
	if not downsample_shader.is_valid():
		return false

	downsample_pipeline = rd.compute_pipeline_create(downsample_shader)
	
	var blur_shader_spirv: RDShaderSPIRV = blur_shader_file.get_spirv()

	if blur_shader_spirv.compile_error_compute != "":
		push_error(blur_shader_spirv.compile_error_compute)
		return false

	blur_shader = rd.shader_create_from_spirv(blur_shader_spirv)
	if not blur_shader.is_valid():
		return false

	blur_pipeline = rd.compute_pipeline_create(blur_shader)
	
	var overlay_shader_spirv: RDShaderSPIRV = overlay_shader_file.get_spirv()

	if overlay_shader_spirv.compile_error_compute != "":
		push_error(overlay_shader_spirv.compile_error_compute)
		return false

	overlay_shader = rd.shader_create_from_spirv(overlay_shader_spirv)
	if not overlay_shader.is_valid():
		return false

	overlay_pipeline = rd.compute_pipeline_create(overlay_shader)


# Check if our shader has changed and needs to be recompiled.
func compile_shader(shader_file, shader, pipeline):
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()

	if shader_spirv.compile_error_compute != "":
		push_error(shader_spirv.compile_error_compute)
		return false

	shader = rd.shader_create_from_spirv(shader_spirv)
	if not shader.is_valid():
		return false

	pipeline = rd.compute_pipeline_create(shader)
	return pipeline.is_valid()


func validate_pipelines():
	return lens_pipeline.is_valid() && downsample_pipeline.is_valid()


func get_image_uniform(image : RID, binding : int = 0) -> RDUniform:
	var uniform : RDUniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = binding
	uniform.add_id(image)

	return uniform


func get_texture_uniform(texture: Texture, binding : int = 0) -> RDUniform:
	var sampler_state = RDSamplerState.new()
	sampler_state.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	sampler_state.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	sampler_state.repeat_w = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.mip_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	
	var texture_sampler = rd.sampler_create(sampler_state)
	
	var uniform : RDUniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uniform.binding = binding
	uniform.add_id(texture_sampler)
	uniform.add_id(RenderingServer.texture_get_rd_texture(texture.get_rid(), true))

	return uniform


# Called by the rendering thread every frame.
func _render_callback(p_effect_callback_type, p_render_data):
	if rd and p_effect_callback_type == EFFECT_CALLBACK_TYPE_POST_TRANSPARENT and validate_pipelines():
		# Get our render scene buffers object, this gives us access to our render buffers.
		# Note that implementation differs per renderer hence the need for the cast.
		var render_scene_buffers: RenderSceneBuffersRD = p_render_data.get_render_scene_buffers()
		if render_scene_buffers:
			# Get our render size, this is the 3D render resolution!
			var size = render_scene_buffers.get_internal_size()
			if size.x == 0 and size.y == 0:
				return

			# We can use a compute shader here.
			var x_groups = (size.x - 1) / 8 + 1
			var y_groups = (size.y - 1) / 8 + 1
			var z_groups = 1

			# Push constant.
			var push_constant: PackedFloat32Array = PackedFloat32Array()
			push_constant.push_back(size.x)
			push_constant.push_back(size.y)
			push_constant.push_back(gaussian_blur_size)
			push_constant.push_back(gaussian_blur_size)

			# Loop through views just in case we're doing stereo rendering. No extra cost if this is mono.
			var view_count = render_scene_buffers.get_view_count()
			for view in range(view_count):
				# Get the RID for our color image, we will be reading from and writing to it.
				var input_image = render_scene_buffers.get_color_layer(view)
				
				var usage_bits : int = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
				# Create downsample texture
				render_scene_buffers.create_texture(
					context, 
					"Ping", 
					RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT, 
					usage_bits, 
					RenderingDevice.TEXTURE_SAMPLES_1, 
					size, 1, 1, true, false)
				render_scene_buffers.create_texture(
					context, 
					"Pong", 
					RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT, 
					usage_bits, 
					RenderingDevice.TEXTURE_SAMPLES_1, 
					size, 1, 1, true, false)
				
				var color_uniform: RDUniform = RDUniform.new()
				color_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
				color_uniform.binding = 0
				color_uniform.add_id(input_image)
				
				var ping_uniform = get_image_uniform(render_scene_buffers.get_texture(context, "Ping"))
				var pong_uniform = get_image_uniform(render_scene_buffers.get_texture(context, "Pong"))
				
				var color_uniform_set := UniformSetCacheRD.get_cache(lens_shader, 0, [ color_uniform ])
				var ping_uniform_set := UniformSetCacheRD.get_cache(lens_shader, 1, [ping_uniform])
				
				# Downsample
				var compute_list := rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, downsample_pipeline)
				rd.compute_list_bind_uniform_set(compute_list, color_uniform_set, 0)
				rd.compute_list_bind_uniform_set(compute_list, ping_uniform_set, 1)
				rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
				rd.compute_list_end()

				## Create a uniform set.
				## This will be cached; the cache will be cleared if our viewport's configuration is changed.
				#var uniform: RDUniform = RDUniform.new()
				#uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
				#uniform.binding = 0
				#uniform.add_id(input_image)
				#var uniform_set = UniformSetCacheRD.get_cache(lens_shader, 0, [ uniform ])
				
				var color_ramp_uniform = get_texture_uniform(lens_flare_color_ramp)
				
				ping_uniform_set = UniformSetCacheRD.get_cache(lens_shader, 0, [ ping_uniform ])
				var pong_uniform_set = UniformSetCacheRD.get_cache(lens_shader, 1, [pong_uniform])
				var color_ramp_uniform_set = UniformSetCacheRD.get_cache(lens_shader, 2, [color_ramp_uniform])

				# Run lens flare
				compute_list = rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, lens_pipeline)
				rd.compute_list_bind_uniform_set(compute_list, ping_uniform_set, 0)
				rd.compute_list_bind_uniform_set(compute_list, pong_uniform_set, 1)
				rd.compute_list_bind_uniform_set(compute_list, color_ramp_uniform_set, 2)
				rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
				rd.compute_list_end()
				
				# Run blur
				var blur_push_constant: PackedFloat32Array = PackedFloat32Array()
				blur_push_constant.push_back(size.x)
				blur_push_constant.push_back(size.y)
				blur_push_constant.push_back(gaussian_blur_size)
				blur_push_constant.push_back(0.0)
				
				var blur_color_uniform_set = UniformSetCacheRD.get_cache(blur_shader, 0, [ pong_uniform ])
				var blur_texture_uniform_set = UniformSetCacheRD.get_cache(blur_shader, 1, [ ping_uniform ])

				compute_list = rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, blur_pipeline)
				rd.compute_list_bind_uniform_set(compute_list, blur_color_uniform_set, 0)
				rd.compute_list_bind_uniform_set(compute_list, blur_texture_uniform_set, 1)
				rd.compute_list_set_push_constant(compute_list, blur_push_constant.to_byte_array(), blur_push_constant.size() * 4)
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
				rd.compute_list_end()
				
				rd.draw_command_end_label()
				
				# Run blur again vertically
				blur_push_constant = PackedFloat32Array()
				blur_push_constant.push_back(size.x)
				blur_push_constant.push_back(size.y)
				blur_push_constant.push_back(0.0)
				blur_push_constant.push_back(gaussian_blur_size)
				
				blur_color_uniform_set = UniformSetCacheRD.get_cache(blur_shader, 0, [ ping_uniform ])
				blur_texture_uniform_set = UniformSetCacheRD.get_cache(blur_shader, 1, [ pong_uniform ])
				
				compute_list = rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, blur_pipeline)
				rd.compute_list_bind_uniform_set(compute_list, blur_color_uniform_set, 0)
				rd.compute_list_bind_uniform_set(compute_list, blur_texture_uniform_set, 1)
				rd.compute_list_set_push_constant(compute_list, blur_push_constant.to_byte_array(), blur_push_constant.size() * 4)
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
				rd.compute_list_end()
				
				# Last step: overlay
				var overlay_uniform_set_1 = UniformSetCacheRD.get_cache(overlay_shader, 0, [ pong_uniform ])
				var overlay_uniform_set_2 = UniformSetCacheRD.get_cache(overlay_shader, 1, [ color_uniform ])
				
				compute_list = rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, overlay_pipeline)
				rd.compute_list_bind_uniform_set(compute_list, overlay_uniform_set_1, 0)
				rd.compute_list_bind_uniform_set(compute_list, overlay_uniform_set_2, 1)
				rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
				rd.compute_list_end()
