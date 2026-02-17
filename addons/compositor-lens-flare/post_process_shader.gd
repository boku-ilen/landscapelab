@tool
extends CompositorEffect
class_name PostProcessShader

# Lens flare effect based on https://john-chapman-graphics.blogspot.com/2013/02/pseudo-lens-flare.html
# References used for CompositorEffect structure:
# - https://github.com/pink-arcana/godot-distance-field-outlines
# - https://github.com/BastiaanOlij/RERadialSunRays

var context := "LENS_FLARE"

var downsample_shader_file = load("res://addons/compositor-lens-flare/downsample.glsl")
var lens_shader_file = load("res://addons/compositor-lens-flare/lens.glsl")
var blur_shader_file = load("res://addons/compositor-lens-flare/gaussian_blur.glsl")
var overlay_shader_file = load("res://addons/compositor-lens-flare/overlay.glsl")
var streak_shader_file = load("res://addons/compositor-lens-flare/streak.glsl")

@export_tool_button("Reload", "Callable") var reload_action = reload

@export_group("Downsample", "downsample_")
@export_range(0.0, 5.0) var downsample_scale := 0.2
@export_range(0.0, 5.0) var downsample_bias := 0.6
@export_range(0.0, 1.0) var downsample_desaturation := 0.5

@export_group("Glare", "glare_")
@export_range(0, 12) var glare_streak_count := 6
@export_range(0.8, 1.0) var glare_attenuation: float = 0.975
@export_range(1, 12) var glare_samples: int = 4

@export_group("Lens Flare", "flare_")
@export var flare_color_ramp: Texture2D
@export_range(1, 16) var flare_ghost_count := 8
@export_range(0.0, 2.0) var flare_ghost_dispersal := 0.25
@export_range(0.0, 10.0) var flare_chromatic_abberation_scale := 7.0
@export_range(0.0, 1.0) var flare_halo_width := 0.4
@export_range(1.0, 10.0) var flare_halo_weight_power := 5.0

@export_group("Guassian Blur", "gaussian_blur_")
@export_range(5.0, 50.0) var gaussian_blur_size: float = 16.0

@export_group("Overlay", "overlay_")
@export var overlay_dirt_texture: Texture2D
@export var overlay_white_texture: Texture2D
@export_range(0.0, 1.0) var overlay_dirt_texture_power := 0.6

var downsample_shader: RID
var downsample_pipeline: RID

var lens_shader: RID
var lens_pipeline: RID

var blur_shader: RID
var blur_pipeline: RID

var overlay_shader: RID
var overlay_pipeline: RID

var streak_shader: RID
var streak_pipeline: RID

var rd: RenderingDevice

var mutex: Mutex = Mutex.new()
var shader_is_dirty: bool = true

var clamp_linear_texture_sampler: RID

# Called when this resource is constructed.
func _init():
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	RenderingServer.call_on_render_thread(_initialize_compute)


# System notifications, we want to react on the notification that
# alerts us we are about to be destroyed.
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		cleanup()


func cleanup():
	if lens_shader.is_valid():
		rd.free_rid(lens_shader)
	if downsample_shader.is_valid():
		rd.free_rid(downsample_shader)
	if blur_shader.is_valid():
		rd.free_rid(blur_shader)
	if overlay_shader.is_valid():
		rd.free_rid(overlay_shader)
	if streak_shader.is_valid():
		rd.free_rid(streak_shader)


func reload():
	cleanup()
	
	RenderingServer.call_on_render_thread(_initialize_compute)


func _initialize_compute():
	rd = RenderingServer.get_rendering_device()
	
	# Create samplers
	clamp_linear_texture_sampler = create_texture_sampler()
	
	# Compile all shaders and create pipelines
	
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
	
	var streak_shader_spirv: RDShaderSPIRV = streak_shader_file.get_spirv()

	if streak_shader_spirv.compile_error_compute != "":
		push_error(streak_shader_spirv.compile_error_compute)
		return false

	streak_shader = rd.shader_create_from_spirv(streak_shader_spirv)
	if not streak_shader.is_valid():
		return false

	streak_pipeline = rd.compute_pipeline_create(streak_shader)


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
	return lens_pipeline.is_valid() and downsample_pipeline.is_valid() \
			and blur_pipeline.is_valid() and streak_pipeline.is_valid() \
			and overlay_pipeline.is_valid()


func get_image_uniform(image : RID, binding : int = 0) -> RDUniform:
	var uniform : RDUniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = binding
	uniform.add_id(image)

	return uniform


func create_texture_sampler():
	var sampler_state = RDSamplerState.new()
	sampler_state.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	sampler_state.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	sampler_state.repeat_w = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.mip_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	
	return rd.sampler_create(sampler_state)


func get_texture_uniform(texture: Texture, binding : int = 0) -> RDUniform:
	var uniform : RDUniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uniform.binding = binding
	uniform.add_id(clamp_linear_texture_sampler)
	uniform.add_id(RenderingServer.texture_get_rd_texture(texture.get_rid(), true))

	return uniform


# Called by the rendering thread every frame.
func _render_callback(p_effect_callback_type, p_render_data):
	if rd and p_effect_callback_type == EFFECT_CALLBACK_TYPE_POST_TRANSPARENT \
			and validate_pipelines():
		# Get our render scene buffers object, this gives us access to our render buffers.
		# Note that implementation differs per renderer hence the need for the cast.
		var render_scene_buffers: RenderSceneBuffersRD = p_render_data.get_render_scene_buffers()
		if render_scene_buffers:
			# Get our render size, this is the 3D render resolution!
			var size = render_scene_buffers.get_internal_size()
			if size.x == 0 and size.y == 0:
				return

			# Compute shader groups
			var x_groups = (size.x - 1) / 8 + 1
			var y_groups = (size.y - 1) / 8 + 1
			var z_groups = 1

			# Loop through views just in case we're doing stereo rendering.
			# No extra cost if this is mono.
			var view_count = render_scene_buffers.get_view_count()
			for view in range(view_count):
				# Get the RID for our color image, we will be reading from and writing to it.
				var input_image = render_scene_buffers.get_color_layer(view)
				
				var usage_bits := RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT \
						| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
				
				# Create textures (or get from cache if already created)
				render_scene_buffers.create_texture(
					context, 
					"Downsampled", 
					RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT, 
					usage_bits, 
					RenderingDevice.TEXTURE_SAMPLES_1, 
					size, 1, 1, true, false)
				render_scene_buffers.create_texture(
					context, 
					"BlurLeft", 
					RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT, 
					usage_bits, 
					RenderingDevice.TEXTURE_SAMPLES_1, 
					size, 1, 1, true, false)
				render_scene_buffers.create_texture(
					context, 
					"BlurRight", 
					RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT, 
					usage_bits, 
					RenderingDevice.TEXTURE_SAMPLES_1, 
					size, 1, 1, true, false)
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
				
				var downsampled_uniform = get_image_uniform(render_scene_buffers.get_texture(context, "Downsampled"))
				var ping_uniform = get_image_uniform(render_scene_buffers.get_texture(context, "Ping"))
				var pong_uniform = get_image_uniform(render_scene_buffers.get_texture(context, "Pong"))
				var blur_left_uniform = get_image_uniform(render_scene_buffers.get_texture(context, "BlurLeft"))
				var blur_right_uniform = get_image_uniform(render_scene_buffers.get_texture(context, "BlurRight"))
				
				# Setup done
				
				# Step 1: Downsample
				# Extracts only bright bits from texture, making the rest black
				
				var downsample_uniform_set_1 := UniformSetCacheRD.get_cache(lens_shader, 0, [ color_uniform ])
				var downsample_uniform_set_2 := UniformSetCacheRD.get_cache(lens_shader, 1, [ downsampled_uniform ])
				
				var downsample_push_constant := PackedByteArray()
				downsample_push_constant.resize(32)
				downsample_push_constant.encode_float(0, size.x)
				downsample_push_constant.encode_float(4, size.y)
				downsample_push_constant.encode_float(8, downsample_scale)
				downsample_push_constant.encode_float(12, downsample_bias)
				downsample_push_constant.encode_float(16, downsample_desaturation)
				
				var compute_list := rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, downsample_pipeline)
				rd.compute_list_bind_uniform_set(compute_list, downsample_uniform_set_1, 0)
				rd.compute_list_bind_uniform_set(compute_list, downsample_uniform_set_2, 1)
				rd.compute_list_set_push_constant(compute_list, downsample_push_constant, downsample_push_constant.size())
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
				rd.compute_list_end()
				
				# Step 2: Light streak
				# Blurs the texture into any number of directions and overlays the result onto the
				# color buffer
				
				for angle_i in range(glare_streak_count): # hexagonal streaks
					var angle_here = ((PI * 2.0) / glare_streak_count) * angle_i
					var direction = Vector2(1.0, 0.0).rotated(angle_here)
					
					# We have a lot of code duplication here instead of looping because we need to
					# ping-pong the "from" and "to" textures:
					# downsampled -> ping -> pong -> ping -> pong -> color
					# TODO: could probably be cleaned up with a lambda
					
					var streak_uniform_set
					var streak_uniform_set2
					
					# Iteration 1
					var streak_push_constant: PackedByteArray = PackedByteArray()
					streak_push_constant.resize(32)
					streak_push_constant.encode_float(0, size.x)
					streak_push_constant.encode_float(4, size.y)
					streak_push_constant.encode_float(8, direction.x * 1.0) # Direction
					streak_push_constant.encode_float(12, direction.y * 1.0)
					streak_push_constant.encode_s32(16, glare_samples) # Samples
					streak_push_constant.encode_float(20, glare_attenuation) # Attenuation
					streak_push_constant.encode_s32(24, 0) # Iteration
					
					streak_uniform_set = UniformSetCacheRD.get_cache(streak_shader, 0, [downsampled_uniform])
					streak_uniform_set2 = UniformSetCacheRD.get_cache(streak_shader, 1, [ping_uniform])
						
					compute_list = rd.compute_list_begin()
					rd.compute_list_bind_compute_pipeline(compute_list, streak_pipeline)
					rd.compute_list_bind_uniform_set(compute_list, streak_uniform_set, 0)
					rd.compute_list_bind_uniform_set(compute_list, streak_uniform_set2, 1)
					rd.compute_list_set_push_constant(compute_list, streak_push_constant, streak_push_constant.size())
					rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
					rd.compute_list_end()
					
					# Iteration 2
					streak_push_constant = PackedByteArray()
					streak_push_constant.resize(32)
					streak_push_constant.encode_float(0, size.x)
					streak_push_constant.encode_float(4, size.y)
					streak_push_constant.encode_float(8, direction.x * 1.0) # Direction
					streak_push_constant.encode_float(12, direction.y * 1.0)
					streak_push_constant.encode_s32(16, glare_samples) # Samples
					streak_push_constant.encode_float(20, glare_attenuation) # Attenuation
					streak_push_constant.encode_s32(24, 1) # Iteration
					
					streak_uniform_set = UniformSetCacheRD.get_cache(streak_shader, 0, [ping_uniform])
					streak_uniform_set2 = UniformSetCacheRD.get_cache(streak_shader, 1, [pong_uniform])
						
					compute_list = rd.compute_list_begin()
					rd.compute_list_bind_compute_pipeline(compute_list, streak_pipeline)
					rd.compute_list_bind_uniform_set(compute_list, streak_uniform_set, 0)
					rd.compute_list_bind_uniform_set(compute_list, streak_uniform_set2, 1)
					rd.compute_list_set_push_constant(compute_list, streak_push_constant, streak_push_constant.size())
					rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
					rd.compute_list_end()
					
					# Iteration 3
					streak_push_constant = PackedByteArray()
					streak_push_constant.resize(32)
					streak_push_constant.encode_float(0, size.x)
					streak_push_constant.encode_float(4, size.y)
					streak_push_constant.encode_float(8, direction.x * 1.0) # Direction
					streak_push_constant.encode_float(12, direction.y * 1.0)
					streak_push_constant.encode_s32(16, glare_samples) # Samples
					streak_push_constant.encode_float(20, glare_attenuation) # Attenuation
					streak_push_constant.encode_s32(24, 2) # Iteration
					
					streak_uniform_set = UniformSetCacheRD.get_cache(streak_shader, 0, [pong_uniform])
					streak_uniform_set2 = UniformSetCacheRD.get_cache(streak_shader, 1, [ping_uniform])
						
					compute_list = rd.compute_list_begin()
					rd.compute_list_bind_compute_pipeline(compute_list, streak_pipeline)
					rd.compute_list_bind_uniform_set(compute_list, streak_uniform_set, 0)
					rd.compute_list_bind_uniform_set(compute_list, streak_uniform_set2, 1)
					rd.compute_list_set_push_constant(compute_list, streak_push_constant, streak_push_constant.size())
					rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
					rd.compute_list_end()
					
					# Iteration 4
					streak_push_constant = PackedByteArray()
					streak_push_constant.resize(32)
					streak_push_constant.encode_float(0, size.x)
					streak_push_constant.encode_float(4, size.y)
					streak_push_constant.encode_float(8, direction.x * 1.0) # Direction
					streak_push_constant.encode_float(12, direction.y * 1.0)
					streak_push_constant.encode_s32(16, glare_samples) # Samples
					streak_push_constant.encode_float(20, glare_attenuation) # Attenuation
					streak_push_constant.encode_s32(24, 3) # Iteration
					
					streak_uniform_set = UniformSetCacheRD.get_cache(streak_shader, 0, [ping_uniform])
					streak_uniform_set2 = UniformSetCacheRD.get_cache(streak_shader, 1, [pong_uniform])
						
					compute_list = rd.compute_list_begin()
					rd.compute_list_bind_compute_pipeline(compute_list, streak_pipeline)
					rd.compute_list_bind_uniform_set(compute_list, streak_uniform_set, 0)
					rd.compute_list_bind_uniform_set(compute_list, streak_uniform_set2, 1)
					rd.compute_list_set_push_constant(compute_list, streak_push_constant, streak_push_constant.size())
					rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
					rd.compute_list_end()
					
					# Blur onto color
					var overlay_uniform = get_texture_uniform(overlay_white_texture)
					
					var overlay_uniform_set_1 = UniformSetCacheRD.get_cache(overlay_shader, 0, [ pong_uniform ])
					var overlay_uniform_set_2 = UniformSetCacheRD.get_cache(overlay_shader, 1, [ color_uniform ])
					var overlay_uniform_set_3 = UniformSetCacheRD.get_cache(overlay_shader, 2, [ overlay_uniform ])
					
					var overlay_push_constant: PackedFloat32Array = PackedFloat32Array()
					overlay_push_constant.push_back(size.x)
					overlay_push_constant.push_back(size.y)
					overlay_push_constant.push_back(0.0) # Padding
					overlay_push_constant.push_back(0.0)
					
					compute_list = rd.compute_list_begin()
					rd.compute_list_bind_compute_pipeline(compute_list, overlay_pipeline)
					rd.compute_list_bind_uniform_set(compute_list, overlay_uniform_set_1, 0)
					rd.compute_list_bind_uniform_set(compute_list, overlay_uniform_set_2, 1)
					rd.compute_list_bind_uniform_set(compute_list, overlay_uniform_set_3, 2)
					rd.compute_list_set_push_constant(compute_list, overlay_push_constant.to_byte_array(), overlay_push_constant.size() * 4)
					rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
					rd.compute_list_end()
				
				# Step 3: Lens Flare
				# Create ghosts and halos from the downsampled image
				# (Note: the light streak result is not used in the lens flare processing)
				
				var color_ramp_uniform = get_texture_uniform(flare_color_ramp)
				
				var lens_flare_uniform_set_1 = UniformSetCacheRD.get_cache(lens_shader, 0, [ downsampled_uniform ])
				var lens_flare_uniform_set_2 = UniformSetCacheRD.get_cache(lens_shader, 1, [pong_uniform])
				var lens_flare_uniform_set_3 = UniformSetCacheRD.get_cache(lens_shader, 2, [color_ramp_uniform])
				
				var lens_flare_push_constant := PackedByteArray()
				lens_flare_push_constant.resize(32)
				lens_flare_push_constant.encode_float(0, size.x)
				lens_flare_push_constant.encode_float(4, size.y)
				lens_flare_push_constant.encode_s32(8, flare_ghost_count)
				lens_flare_push_constant.encode_float(12, flare_ghost_dispersal)
				lens_flare_push_constant.encode_float(16, flare_chromatic_abberation_scale)
				lens_flare_push_constant.encode_float(20, flare_halo_width)
				lens_flare_push_constant.encode_float(24, flare_halo_weight_power)

				# Run lens flare
				compute_list = rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, lens_pipeline)
				rd.compute_list_bind_uniform_set(compute_list, lens_flare_uniform_set_1, 0)
				rd.compute_list_bind_uniform_set(compute_list, lens_flare_uniform_set_2, 1)
				rd.compute_list_bind_uniform_set(compute_list, lens_flare_uniform_set_3, 2)
				rd.compute_list_set_push_constant(compute_list, lens_flare_push_constant, lens_flare_push_constant.size())
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
				rd.compute_list_end()
				
				# Step 4: Blur
				# Horizontal, then vertical blur of the lens flare result to make the ghosts less
				# sharp
				
				# Horizontal pass
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
				
				# Vertical pass (using the horizontal result)
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
				
				# Step 5: Overlay
				# Blend the blurred lens flares onto the color buffer (which already includes the
				# light streaks created in step 2)
				
				var overlay_uniform_set_1 = UniformSetCacheRD.get_cache(overlay_shader, 0, [ pong_uniform ])
				var overlay_uniform_set_2 = UniformSetCacheRD.get_cache(overlay_shader, 1, [ color_uniform ])
				
				var dirt_uniform = get_texture_uniform(overlay_dirt_texture)
				var overlay_uniform_set_3 = UniformSetCacheRD.get_cache(overlay_shader, 2, [ dirt_uniform ])
				
				var overlay_push_constant = PackedByteArray()
				overlay_push_constant.resize(16)
				overlay_push_constant.encode_float(0, size.x)
				overlay_push_constant.encode_float(4, size.y)
				overlay_push_constant.encode_float(8, 0.0) # Padding
				overlay_push_constant.encode_float(12, overlay_dirt_texture_power)
				
				compute_list = rd.compute_list_begin()
				rd.compute_list_bind_compute_pipeline(compute_list, overlay_pipeline)
				rd.compute_list_bind_uniform_set(compute_list, overlay_uniform_set_1, 0)
				rd.compute_list_bind_uniform_set(compute_list, overlay_uniform_set_2, 1)
				rd.compute_list_bind_uniform_set(compute_list, overlay_uniform_set_3, 2)
				rd.compute_list_set_push_constant(compute_list, overlay_push_constant, overlay_push_constant.size())
				rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
				rd.compute_list_end()
