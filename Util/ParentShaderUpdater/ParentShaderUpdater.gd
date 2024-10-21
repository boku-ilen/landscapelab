# Set this ParentShaderUpdater (PSU) on a Node parented to a Node which has 3D Mesh & Material/Shader.
# By pressing a button, the Parent's shader is updated from its source file.
# Make changes to the Shader, press button to manually update or use "res_type_saved_messages" plugin for auto-update when saving.

# TO DO: Rework so "current_" arrays are structs of [Material, Path=String, MaterialUsage (what is now GetMaterialsStage)]
extends Node

var parent : Node
var psu = ParentShaderUpdater_MatLib.new() ### PLACEHOLDER TO CALL THE FUNCTION
var surface_count : int # To get multiple SurfaceMats + Overrides on MeshInstance3Ds and Particles.
var canvasitem_mat : Array[Material] # NOT YET IMPLEMENTED, MAYBE NOT NECESSARY?
var surfacemats : Array[Material] # Low priority mat: For Primitive meshes, property "material". For Array meshes, property "surface_0-n/material".
var surfacemats_overrides: Array[Material] # Medium priority mat: For both Primitive and Array meshes, property "surface_material_override/0-n". Not available on Particles.
var geometrymats_overrides : Array[Material] # High priority mat: Only 1, but Array for compatability, property "material_override"
var processmats : Array[Material] # Only 1, only available on GPU particles. Only requires PSU if class ShaderMaterial (ParticleProcessMaterial itself wouldn't require PSU)

var current_any_mats : Array[ParentShaderUpdater_MatLib] # The material(s) in the highest priority slot(s), could be any type.
## var current_any_mats : Array[ParentShaderUpdater_MatLib] = Array[ParentShaderUpdater_MatLib] ### Warum ERRORS? Wie würd ichs sonst richtig leer initialisieren?
var current_any_mats_plus_nextpasses : Array[ParentShaderUpdater_MatLib] # Material(s) in the highest priority slots, plus their potential "Next Pass" materials
var current_updatable_mats : Array[ParentShaderUpdater_MatLib] # Final collection of type ShaderMaterial that will be updated - other types wouldn't require PSU.
var current_updatable_mats_matching_saved : Array[ParentShaderUpdater_MatLib] # Collects only Mats that match the saved resource = Shader.
enum GetMaterialsState { # Tracking the status of get_current_mats()
	INIT = 0, # State when no update procedure has yet started.
	NO_VALIDPARENT = 1, # If PSU is parented to something that doesn't use Materials.
	NO_MAT_FOUND = 2, # No mat of any type is assigned to geo.
	NO_SHADERMAT_FOUND = 3, # Mat is assigned, but isn't of class ShaderMat.
	NO_SHADER_FOUND = 4,  # Mat is assigned and of class ShaderMat, but has no Shader assigned.
	PROCESSING = 5, # TEMP, DELETE LATER
	SUCCESS = 9, # When at least one valid ShaderMat has been found.
}
var get_mats_state : GetMaterialsState
var saved_path: String # Path of the shader that was recently saved in Editor.

# Checks messages in session sent via ResTypeSavedMessages for key string.
func _ready() -> void:
	EngineDebugger.register_message_capture("res_shader_saved", _auto_update_chain)

func _input(event):
	if event.is_action_pressed("parent_shader_updater"):
		_manual_update_chain()


func _manual_update_chain() -> void:
	if _get_current_mats_validate():
		for index in current_updatable_mats:
			_update_shader(index)
	return

func _auto_update_chain(message_string: String, data: Array[String]) -> void:
	saved_path = data[0]
	if _get_current_mats_validate():
		current_updatable_mats_matching_saved = _get_matlibs_matching_shader_path(saved_path, current_updatable_mats)
		if current_updatable_mats_matching_saved.size() > 0:
			for index in current_updatable_mats_matching_saved:
				_update_shader(index)
		else:
			print("PSU: Saved Shader '", saved_path, "' not part of PSU-handled Materials -> Not updatable!")
	return


func _get_current_mats_validate() -> bool:
	parent = get_parent()
	canvasitem_mat.clear()
	surfacemats.clear()
	surfacemats_overrides.clear()
	geometrymats_overrides.clear()
	processmats.clear()
	current_any_mats.clear()
	current_any_mats_plus_nextpasses.clear()
	current_updatable_mats.clear()
	current_any_mats_plus_nextpasses.clear()
	current_updatable_mats_matching_saved.clear()
	get_mats_state = GetMaterialsState.INIT

	
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
		
		get_mats_state = GetMaterialsState.NO_VALIDPARENT
		print("PSU: NO REQUIRED CLASS AS PARENT '", parent.name, " (Class: '", parent.get_class(), "')'  -> No valid Shaders to update!")
		return false
	
	get_mats_state = GetMaterialsState.PROCESSING
	
	# If GPUParticle2D/3D, and their ProcessMat is class ShaderMaterial, add that to to current_any_mats
	if parent is GPUParticles3D or parent is GPUParticles2D :
		if parent.process_material is ShaderMaterial:
			print("PSU: On parent '", parent.name, "' detected ShaderMaterial '", parent.process_material.resource_path.get_file(), "' in ProcessMaterial slot, using Shader '", parent.process_material.shader.resource_path, "'.")
			_append_unique_mat_to_array(parent.process_material, processmats)
			if processmats.size() > 0:
				for index in processmats:
					psu.convert_to_matlib_append_unique_to_array(index, ParentShaderUpdater_MatLib.MaterialSlot.PARTICLEPROCESSMAT, parent, current_any_mats, "Current_Any_Mats")
	
	# Highest Level - Check for Geometry Mat Override - available nearly everywhere. Return True if any found (= skip any further searches).
	if parent is not GPUParticles2D and \
		parent is not FogVolume:
		
		if parent.material_override != null:
			_append_unique_mat_to_array(parent.material_override, geometrymats_overrides)
		
			for index in geometrymats_overrides: 
				if index != null:
					psu.convert_to_matlib_append_unique_to_array(index, ParentShaderUpdater_MatLib.MaterialSlot.GEOMETRYMAT_OVERRIDE, parent, current_any_mats, "Current_Any_Mats")
			if current_any_mats.size() > 0: # Unnecessary check, but maybe for future compatibility
				if _validate_all_current_mats_chain(): ### EDGE CASE WENN ZWAR GEO OR EXISTIERT, aber nicht validated (weil Shader fehlt oder kein ShaderMaterial)
					####
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
	return _validate_all_current_mats_chain()


func _append_unique_mat_to_array(material: Material, array: Array) -> bool: # returns true if material wasn't already in array
	if material not in array:
		array.append(material)
	return material not in array # Ist Blödsinn, weil es dann ja am Ende drinlandet...

func _recurse_nextpass_mat_append_to_array(matlib: ParentShaderUpdater_MatLib, array_matlib: Array[ParentShaderUpdater_MatLib], debug_arrayname : String, recursionloop: int = 1 ) -> void:
	if matlib.material is ShaderMaterial or matlib.material is StandardMaterial3D or matlib.material is ORMMaterial3D:
		var nextpass_mat : Material = matlib.material.next_pass
		
		if nextpass_mat != null:
			# Checks if material_slot is even, if yes, increase the enum to store the "Nextpass" Version of the current slot
			var mat_slot_manipulated = matlib.material_slot
			if not mat_slot_manipulated % 2:
				mat_slot_manipulated += 1
			
			var nextpass_conv_to_matlib : ParentShaderUpdater_MatLib = psu.convert_to_matlib(nextpass_mat, mat_slot_manipulated, parent)
			print("PSU: On Parent '", parent.name, "' Recursion Loop #", recursionloop, " on Mat '", matlib.material.resource_path.get_file(), "' in slot '", matlib.MaterialSlot.keys()[matlib.material_slot], "' to get NextPass-Mat '", nextpass_mat.resource_path.get_file(), "'.")
			psu.append_unique_matlib_to_array(nextpass_conv_to_matlib, array_matlib, debug_arrayname)
			_recurse_nextpass_mat_append_to_array(nextpass_conv_to_matlib, array_matlib, debug_arrayname, recursionloop + 1)
			
	return

func _validate_matlib_for_mattype_and_shader(matlib : ParentShaderUpdater_MatLib) -> bool:	
	if matlib.material is not ShaderMaterial:
			get_mats_state = GetMaterialsState.NO_SHADERMAT_FOUND
			print("PSU: NOT OF CLASS SHADERMATERIAL in Mat '", matlib.material.resource_path.get_file(), "' (Class: '", matlib.material.get_class(), "') in slot '", matlib.MaterialSlot.keys()[matlib.material_slot], "' on '", parent.name, "' -> Not updatable!")
			return false
	if matlib.material.shader == null:
		get_mats_state = GetMaterialsState.NO_SHADER_FOUND
		print("PSU: NO SHADER ASSIGNED to Mat '", matlib.material.resource_path.get_file(), "' in slot '", matlib.MaterialSlot.keys()[matlib.material_slot], "' on '", parent.name, "' -> Not updatable!")
		return false
	return true
	
func _validate_all_current_mats_chain() -> bool:
	# Recurse through current_any_mats to see if some of those contain other next_pass materials, append everything found to current_any_mats_plus_nextpasses array.
	if current_any_mats.size() > 0:
		for index in current_any_mats:
			psu.append_unique_matlib_to_array(index, current_any_mats_plus_nextpasses, "Current_Any_Mats_Plus_Nextpasses")
			_recurse_nextpass_mat_append_to_array(index, current_any_mats_plus_nextpasses, "Current_Any_Mats_Plus_Nextpasses")		

		# Validate then copy Materials from current_any_mats_plus_nextpasses to current_updatable_mats array.
		if current_any_mats_plus_nextpasses.size() > 0:
			for index in current_any_mats_plus_nextpasses:
				if _validate_matlib_for_mattype_and_shader(index):
					psu.append_unique_matlib_to_array(index, current_updatable_mats, "Current_Updatable_Mats")

			# Final check for any mats in current_updatable_mats, write their path to String Array (for Auto Update)
			if current_updatable_mats.size() > 0:
				psu.fill_shader_paths(current_updatable_mats, "Current_Updatable_Mats")
				return true

	print("PSU: NO MAT OF ANY TYPE FOUND found on parent '", parent.name, "' -> Can't Update!")
	get_mats_state = GetMaterialsState.NO_MAT_FOUND
	return false

# Returns an array of all Materials in MatLib format that match the input string (usually Saved Shader Path)
func _get_matlibs_matching_shader_path(search_in_shader_path : String, array_matlib : Array[ParentShaderUpdater_MatLib]) -> Array[ParentShaderUpdater_MatLib]:
	var matching_matlibs : Array[ParentShaderUpdater_MatLib]
	for index in array_matlib:
		if search_in_shader_path == index.shader_path:
			psu.append_unique_matlib_to_array(index, matching_matlibs, "Matching_MatLibs")
	return matching_matlibs

func _update_shader(matlib : ParentShaderUpdater_MatLib) -> void:
	var shader_text = FileAccess.open(matlib.shader_path, FileAccess.READ).get_as_text()
	matlib.material.shader.code = shader_text
	print("PSU: Updated Material '", matlib.material.resource_path.get_file(), "' from Shader '", matlib.shader_path, "'\n \
	(found on parent '", matlib.source_node.name, "' in slot '", psu.MaterialSlot.keys()[matlib.material_slot], "')")
	return
