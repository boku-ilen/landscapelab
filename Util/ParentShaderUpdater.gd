# Set this ParentShaderUpdater (PSU) on a Node parented to a Node which has 3D Mesh & Material/Shader.
# By pressing a button, the Parent's shader is updated from its source file.
# Make changes to the Shader, press button to manually update or use "res_type_saved_messages" plugin for auto-update when saving.

# TO DO: Rework so "current_" arrays are structs of [Material, Path=String, MaterialUsage (what is now CurrentMaterialType)]
extends Node

var parent : Node
var surface_count : int # To get multiple SurfaceMats + Overrides on MeshInstance3Ds and Particles.
var canvasitem_mat : Array[Material] # NOT YET IMPLEMENTED, MAYBE NOT NECESSARY?
var surfacemats : Array[Material] # Low priority mat: For Primitive meshes, property "material". For Array meshes, property "surface_0-n/material".
var surfacemats_overrides: Array[Material] # Medium priority mat: For both Primitive and Array meshes, property "surface_material_override/0-n". Not available on Particles.
var geometrymats_overrides : Array[Material] # High priority mat: Only 1, but Array for compatability, property "material_override"
var processmats : Array[Material] # Only 1, only available on GPU particles. Only requires PSU if class ShaderMaterial (ParticleProcessMaterial itself wouldn't require PSU)
var current_any_mats: Array[Material] # The material(s) in the highest priority slot, could be any type.
var current_any_mats_plus_nextpasses: Array[Material] # Material(s) in the highest priority slots, plus their potential "Next Pass" materials
var current_updatable_mats: Array[ShaderMaterial] # Final collection of type ShaderMaterial that will be updated - other types wouldn't require PSU.
var current_updatable_mats_paths: Array[String] # Final collection of the paths for the corresponding Mats. Used by Auto-Update to check if saved Resource matches one of the handled mats.
enum CurrentMaterialType { # Tracking which is the highest priority Material (= the one displayed and updated) and printing debugs. Not really accurate now
	INIT = 0, # State when no update procedure has yet started
	NO_VALIDPARENT = 1, # If PSU is parented to something that doesn't use Materials
	NO_MAT_FOUND = 2, # No mat of any type is assigned to geo
	NO_SHADERMAT_FOUND = 3, # Mat is assigned, but isn't of class ShaderMat
	NO_SHADER_FOUND = 4,  # Mat is assigned and of class ShaderMat, but has no Shader assigned
	CANVASITEM_MAT = 5, # Mat is assigned for a CanvasItem # NOT YET IMPLEMENTED, MAYBE NOT NECESSARY
	SURFACEMAT = 6, # Low priority: property "material", only used if no SurfaceMat Override exists for that slot
	SURFACEMAT_OVERRIDE = 7,  # Medium priority: property "surface_material_override"
	MIXED_SURFACEMAT_PLUS_OVERRIDE = 8, # When both SurfaceMat + SurfaceMat Override are used == highest priority on Multi-Material meshes
	GEOMETRYMAT_OVERRIDE = 9, # High priority: property "material_override"
}
var current_material_type : CurrentMaterialType
var saved_path: String # Path of the shader that was recently saved in Editor.

# Checks messages in session sent via ResTypeSavedMessages for key string
func _ready() -> void:
	EngineDebugger.register_message_capture("res_shader_saved", _auto_update_chain)

func _input(event):
	if event.is_action_pressed("parent_shader_updater"):
		_manual_update_chain()


func _get_current_mats_validate() -> bool:
	canvasitem_mat.clear()
	surfacemats.clear()
	surfacemats_overrides.clear()
	geometrymats_overrides.clear()
	processmats.clear()
	current_any_mats.clear()
	current_any_mats_plus_nextpasses.clear()
	current_updatable_mats.clear()
	current_updatable_mats_paths.clear()
	current_material_type = CurrentMaterialType.INIT
	
	parent = get_parent()
	
	# Fail if Parent is not of following type (which could use ShaderUpdates)
	# Future TO DO: Implement for CanvasItem/2D stuff as well
	if parent is not MeshInstance3D and \
		parent is not MultiMeshInstance3D and \
		parent is not GPUParticles3D and \
		parent is not CPUParticles3D and \
		parent is not GPUParticles2D and \
		parent is not SpriteBase3D and \
		parent is not FogVolume and \
		parent is not CSGShape3D:
		
		current_material_type = CurrentMaterialType.NO_VALIDPARENT
		print("PSU: NO REQUIRED CLASS AS PARENT '", parent.name, " (Class: '", parent.get_class(), "')'  -> No valid Shaders to update!")
		return false
		
	# If GPUParticle2D/3D, and their ProcessMat is class ShaderMaterial, add that to to current_any_mats
	if parent is GPUParticles3D or parent is GPUParticles2D :
		if parent.process_material is ShaderMaterial:
			print("PSU: On parent '", parent.name, "' detected ShaderMaterial '", parent.process_material.resource_path.get_file(), "' in ProcessMaterial slot, using Shader '", parent.process_material.shader.resource_path, "'.")
			_append_unique_mat_to_array(parent.process_material, processmats)
			if processmats.size() > 0:
				for index in processmats:
					_append_unique_mat_to_array(index, current_any_mats)
	
	# Highest Level - Check for Geometry Mat Override - available nearly everywhere. Return True if any found (= skip any further searches).
	if parent is not GPUParticles2D and \
		parent is not FogVolume:
		
		if parent.material_override != null:
			_append_unique_mat_to_array(parent.material_override, geometrymats_overrides)
		
			for index in geometrymats_overrides: 
				if index != null:
					_append_unique_mat_to_array(index, current_any_mats)
			if current_any_mats.size() > 0: # Unnecessary check, but maybe for future compatibility
				if _validate_all_current_mats_chain(CurrentMaterialType.GEOMETRYMAT_OVERRIDE):
					current_material_type = CurrentMaterialType.GEOMETRYMAT_OVERRIDE
					return true
		
	# Medium Level - Check for Surface Mat Overrides (only available on MeshInstance3D classes)
	if parent is MeshInstance3D:
		surface_count = parent.mesh.get_surface_count()
		surfacemats_overrides.resize(surface_count)
		print("Surface Count on MeshInstance3D '", parent.name, "': '", surface_count, "'.")
		
		for index in surface_count:
			print("Surface OR Mat Index: ", index)
			if parent.get_surface_override_material(index) != null:
				print("Gaga")
				#surfacemats_overrides[index] =   ## ERROR
		print("Surface Mats Overrides Array: ", surfacemats_overrides)

	# Check low-priority = SurfaceMats (for Primitive Meshes, different method to get them)		
	#
	#
	#
	
	if parent is GPUParticles3D:
		for index in parent.draw_passes:
			var current_mesh = parent.get_draw_pass_mesh(index)
			var current_mesh_surfacecount = current_mesh.get_surface_count()
			
			for surfaceindex in current_mesh_surfacecount:
				var current_surface_mat = current_mesh.surface_get_material(surfaceindex)
				_append_unique_mat_to_array(current_surface_mat, surfacemats)

	
	# If nothing else has triggered True yet, do a final validation
	return _validate_all_current_mats_chain(current_material_type)


func _append_unique_mat_to_array(material: Material, array: Array) -> bool: # returns true if material wasn't already in array
	if material not in array:
		array.append(material)
	return material not in array

func _recurse_nextpass_mat_append_to_array(material: Material, array: Array, recursionloop: int = 1) -> void:
	if material is ShaderMaterial or material is StandardMaterial3D or material is ORMMaterial3D:
		var nextpass_mat : Material = material.next_pass
		
		if nextpass_mat != null:
			_append_unique_mat_to_array(nextpass_mat, array)
			print("PSU: Recursion Loop #", recursionloop, " on Mat '", material.resource_path.get_file(), "' to get NextPass-Mat '", nextpass_mat.resource_path.get_file(), "'.")
			_recurse_nextpass_mat_append_to_array(nextpass_mat, array, recursionloop + 1)
			
	return

func _validate_mat_for_mattype_and_shader(material : Material, materialtype : CurrentMaterialType) -> bool:	
	if material is not ShaderMaterial:
			print("PSU: NOT OF CLASS SHADERMATERIAL in Mat '", material.resource_path.get_file(), "' (Class: '", material.get_class(), "') in slot '", CurrentMaterialType.keys()[materialtype], "' on parent '", parent.name, "' -> Not updatable!")
			current_material_type = CurrentMaterialType.NO_SHADERMAT_FOUND
			return false
	if material.shader == null:
		print("PSU: NO SHADER ASSIGNED to Mat '", material.resource_path.get_file(), "' in slot '", CurrentMaterialType.keys()[materialtype], "' on parent '", parent.name, "' -> Not updatable!")
		current_material_type = CurrentMaterialType.NO_SHADER_FOUND
		return false
	return true
	
func _validate_all_current_mats_chain(materialtype : CurrentMaterialType) -> bool:
	# Recurse through current_any_mats to see if some of those contain other next_pass materials, append everything found to current_any_mats_plus_nextpasses array.
	if current_any_mats.size() > 0:
		for index in current_any_mats:
			_append_unique_mat_to_array(index, current_any_mats_plus_nextpasses)
			_recurse_nextpass_mat_append_to_array(index, current_any_mats_plus_nextpasses)		

		# Validate then copy Materials from current_any_mats_plus_nextpasses to current_updatable_mats array.
		if current_any_mats_plus_nextpasses.size() > 0:
			for index in current_any_mats_plus_nextpasses:
				if _validate_mat_for_mattype_and_shader(index, materialtype):
					_append_unique_mat_to_array(index, current_updatable_mats)

			# Final check for any mats in current_updatable_mats, write their path to String Array (for Auto Update)
			if current_updatable_mats.size() > 0:
				current_updatable_mats_paths.resize(current_updatable_mats.size())
				for index in range(current_updatable_mats.size()):
					current_updatable_mats_paths[index] = current_updatable_mats[index].shader.resource_path
				return true

	print("PSU: NO MAT OF ANY TYPE FOUND found on parent '", parent.name, "' -> Can't Update!")
	current_material_type = CurrentMaterialType.NO_MAT_FOUND
	return false


func _manual_update_chain() -> void:
	if _get_current_mats_validate():
		for index in current_updatable_mats:
			_update_shader(index)
	return

func _auto_update_chain(message_string: String, data: Array[String]) -> void:
	saved_path = data[0]
	var found_in_current_paths: int
	if _get_current_mats_validate():
		found_in_current_paths = _find_res_shader_saved_in_current_paths()
		if found_in_current_paths >= 0:
			_update_shader(current_updatable_mats[found_in_current_paths])
	return

func _find_res_shader_saved_in_current_paths() -> int: # If saved path not found within currently handled PSU-mats, returns -1 - otherwise index of Array where the updated mat sits.
	if saved_path not in current_updatable_mats_paths: 
		print("PSU: Saved Shader at '", saved_path, "' not part of PSU-handled Shader(s) at '", current_updatable_mats_paths, "' -> No Update!")
	return current_updatable_mats_paths.find(saved_path)

func _update_shader(material: Material) -> void:
	var current_path = material.shader.resource_path
	var shadertext = FileAccess.open(current_path, FileAccess.READ).get_as_text()
	material.shader.code = shadertext
	print("PSU: On parent '", parent.name, "' updated Shader '", current_path, "'\n (for Mat '", material.resource_path.get_file(), "' in slot '", CurrentMaterialType.keys()[current_material_type], "')")
	return
