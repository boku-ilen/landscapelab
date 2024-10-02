# Set this ParentShaderUpdater (PSU) on a Node parented to a Node which has 3D Mesh & Material/Shader.
# By pressing a button, the Parent's shader is updated from its source file.
# Make changes to the Shader, press button to manually update or use "res_type_saved_messages" plugin for auto-update when saving.
extends Node

var parent : Node
var geometrymat_override : Material
var surfacemat_override: Material
var meshmat : Material
var current_material: ShaderMaterial # Is validated to make sure it's of type ShaderMaterial - other types wouldn't require PSU.
enum CurrentMaterialType { # For tracking the state and printing debugs
	NO_GEOMETRYINSTANCE3D = 0, # If PSU is parented to something that doesn't render geometry
	NO_MAT_FOUND = 1, # No mat of any type is assigned to geo
	NO_SHADERMAT_FOUND = 2, # Mat is assigned, but isn't of class ShaderMat
	NO_SHADER_FOUND = 3,  # Mat is assigned and of class ShaderMat, but has no Shader assigned
	MESHMAT = 4, # Low level priority mat: property "material"
	SURFACEMAT_OVERRIDE = 5,  # Mid Level priority mat: property "surface_material_override"
	GEOMETRYMAT_OVERRIDE = 6, # Highest level override: property "material_override"
}
var current_material_type : CurrentMaterialType
var saved_path: String # Path of the shader that was recently saved in Editor.
var current_path: String # Path of the shader being handled by ParentShaderUpdater. # Superfluos? Just use .


# Checks messages in session sent via ResTypeSavedMessages for key string
func _ready() -> void:
	EngineDebugger.register_message_capture("res_shader_saved", _auto_update_chain)

func _manual_update_chain() -> void:
	if _validate_current_material():
		_update_shader()
	return

func _auto_update_chain(message_string: String, data: Array[String]) -> void:
	saved_path = data[0]
	if _validate_current_material():
		if _compare_res_shader_saved_with_current():
			_update_shader()
	return

func _compare_res_shader_saved_with_current() -> bool:
	if saved_path != current_path: 
		print("PSU: Saved Shader at '", saved_path, "' != PSU-handled Shader at '", current_path, "' -> No Update!")
	return saved_path == current_path

func _update_shader() -> void:
	var shadertext = FileAccess.open(current_path, FileAccess.READ).get_as_text()
	current_material.shader.code = shadertext
	print("PSU: On parent '", parent.name, "' updated Shader '", current_path, "'\n (for Mat '", current_material, "' in slot '", CurrentMaterialType.keys()[current_material_type], "'.")
	return

func _validate_current_material() -> bool:
	parent = get_parent()
	if parent is not GeometryInstance3D:
		current_material_type = CurrentMaterialType.NO_GEOMETRYINSTANCE3D
		print("PSU: NO 3D GEOMETRY in parent '", parent.name, "'  -> Can't update Shader!")
		return false
	
	geometrymat_override = parent.material_override
	surfacemat_override = parent.get_surface_override_material(0)
	meshmat = parent.mesh.material
	
	if geometrymat_override != null:
		return _validate_shadermaterial_and_path(geometrymat_override, CurrentMaterialType.GEOMETRYMAT_OVERRIDE)

	if surfacemat_override != null:
		return _validate_shadermaterial_and_path(surfacemat_override, CurrentMaterialType.SURFACEMAT_OVERRIDE)

	if meshmat != null:
		return _validate_shadermaterial_and_path(meshmat, CurrentMaterialType.MESHMAT)

	print("PSU: NO MAT OF ANY TYPE FOUND found on parent '", parent.name, "' -> Can't Update!")
	current_material_type = CurrentMaterialType.NO_MAT_FOUND
	return false

func _validate_shadermaterial_and_path(material : Material, materialtype : CurrentMaterialType) -> bool:
	if material.get_class() != "ShaderMaterial":
		current_material_type = CurrentMaterialType.NO_SHADERMAT_FOUND
		print("PSU: NOT OF TYPE SHADER_MATERIAL in Mat '", material, "' in slot '", CurrentMaterialType.keys()[materialtype], "' on parent '", parent.name, "' -> Can't Update Shader!")
		return false
	
	if material.shader == null:
		current_material_type = CurrentMaterialType.NO_SHADER_FOUND
		print("PSU: NO SHADER ASSIGNED to Mat '", material, "' in slot '", CurrentMaterialType.keys()[materialtype], "' on parent '", parent.name, "' -> Can't Update Shader!")
		return false
	
	current_material = material
	current_material_type = materialtype
	current_path = current_material.shader.resource_path
	#print("PSU: On parent '", parent.name, "' found Mat '", current_material, "' in highest-priority slot '", CurrentMaterialType.keys()[materialtype], "', using this for Shader Update.")
	return true

func _input(event):
	if event.is_action_pressed("parent_shader_updater"):
		_manual_update_chain()
