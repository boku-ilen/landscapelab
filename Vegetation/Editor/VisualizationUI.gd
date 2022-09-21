extends SubViewportContainer


func _ready():
	$CameraButtons/GroundViewButton.connect("pressed",Callable(self,"_change_camera_view").bind(1.6))
	$CameraButtons/CanopyViewButton.connect("pressed",Callable(self,"_change_camera_view").bind(20, -0.2))
	$CameraButtons/AirViewButton.connect("pressed",Callable(self,"_change_camera_view").bind(50, -0.6))
	
	# Camera3D Settings
	$CameraButtons/ViewSettingsButton/ViewSettingsDialog.connect("new_fov",Callable(self,"_change_fov"))
	$CameraButtons/ViewSettingsButton/ViewSettingsDialog.connect("new_view_distance",Callable(self,"_change_view_distance"))
	
	# Texture2D Settings
	$CameraButtons/TextureSettingsButton/TextureSettingsDialog.connect("new_normal_scale", Callable(self,
			"_new_ground_shader_param").bind("normal_scale"))
	$CameraButtons/TextureSettingsButton/TextureSettingsDialog.connect("new_roughness_scale", Callable(self,
			"_new_asymmetric_ground_shader_param").bind("roughness_scale", "is_roughness_increase"))
	$CameraButtons/TextureSettingsButton/TextureSettingsDialog.connect("new_specular_scale", Callable(self,
			"_new_asymmetric_ground_shader_param").bind("specular_scale", "is_specular_increase"))
	$CameraButtons/TextureSettingsButton/TextureSettingsDialog.connect("new_ao_scale", Callable(self,
			"_new_asymmetric_ground_shader_param").bind("ao_scale", "is_ao_increase"))


func _change_fov(value: float):
	$SubViewport/Visualization/ClickDragCamera.fov = value


func _change_view_distance(value: float):
	Vegetation.plant_extent_factor = value


func _change_camera_view(height, angle=0):
	$SubViewport/Visualization/ClickDragCamera.position.y = height
	$SubViewport/Visualization/ClickDragCamera.rotation.x = angle


func _new_ground_shader_param(value, param_name: String):
	$SubViewport/Visualization/GroundMesh.get_surface_override_material(0).set_shader_parameter(param_name, value)


func _new_asymmetric_ground_shader_param(value: float, is_increase: bool, scale_name: String, increase_name: String):
	$SubViewport/Visualization/GroundMesh.get_surface_override_material(0).set_shader_parameter(scale_name, value)
	$SubViewport/Visualization/GroundMesh.get_surface_override_material(0).set_shader_parameter(increase_name, is_increase)
