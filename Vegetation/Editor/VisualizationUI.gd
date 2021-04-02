extends ViewportContainer


func _ready():
	$CameraButtons/GroundViewButton.connect("pressed", self, "_change_camera_view", [2])
	$CameraButtons/CanopyViewButton.connect("pressed", self, "_change_camera_view", [20, -20])
	$CameraButtons/AirViewButton.connect("pressed", self, "_change_camera_view", [50, -45])
	
	# Camera Settings
	$CameraButtons/ViewSettingsButton/ViewSettingsDialog.connect("new_fov", self, "_change_fov")
	$CameraButtons/ViewSettingsButton/ViewSettingsDialog.connect("new_view_distance", self, "_change_view_distance")
	
	# Texture Settings
	$CameraButtons/TextureSettingsButton/TextureSettingsDialog.connect("new_normal_scale", self,
			"_new_ground_shader_param", ["normal_scale"])
	$CameraButtons/TextureSettingsButton/TextureSettingsDialog.connect("new_roughness_scale", self,
			"_new_asymmetric_ground_shader_param", ["roughness_scale", "is_roughness_increase"])
	$CameraButtons/TextureSettingsButton/TextureSettingsDialog.connect("new_specular_scale", self,
			"_new_asymmetric_ground_shader_param", ["specular_scale", "is_specular_increase"])
	$CameraButtons/TextureSettingsButton/TextureSettingsDialog.connect("new_ao_scale", self,
			"_new_asymmetric_ground_shader_param", ["ao_scale", "is_ao_increase"])


func _change_fov(value: float):
	$Viewport/Visualization/ClickDragCamera.fov = value


func _change_view_distance(value: float):
	pass # TODO


func _change_camera_view(height, angle=0):
	$Viewport/Visualization/ClickDragCamera.translation.y = height
	$Viewport/Visualization/ClickDragCamera.rotation_degrees.x = angle


func _new_ground_shader_param(value, param_name: String):
	$Viewport/Visualization/GroundMesh.get_surface_material(0).set_shader_param(param_name, value)


func _new_asymmetric_ground_shader_param(value: float, is_increase: bool, scale_name: String, increase_name: String):
	$Viewport/Visualization/GroundMesh.get_surface_material(0).set_shader_param(scale_name, value)
	$Viewport/Visualization/GroundMesh.get_surface_material(0).set_shader_param(increase_name, is_increase)
