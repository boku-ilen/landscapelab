class_name ParentShaderUpdater_MatLib extends Object

# Tracks in which usage slot the material was found first - for debug printing. ### But should not appear as CONSTANT in the Arrays
enum MaterialSlot {
	PARTICLEPROCESSMAT = 0, # Additional type found on GPU particles
	PARTICLEPROCESSMAT_NEXTPASS = 1, # Nextpass Mat
	CANVASITEMMAT = 2, # Mat is assigned on CanvasItem # NOT YET IMPLEMENTED, MAYBE NOT NECESSARY
	CANVASITEMMAT_NEXTPASS = 3, # Nextpass Mat
	SURFACEMAT = 4, # Low priority: property "material", only used if no SurfaceMat Override exists for that slot
	SURFACEMAT_NEXTPASS = 5, # Nextpass Mat
	SURFACEMAT_OVERRIDE = 6,  # Medium priority: property "surface_material_override"
	SURFACEMAT_OVERRIDE_NEXTPASS = 7,  # Nextpass Mat
	GEOMETRYMAT_OVERRIDE = 8, # High priority: property "material_override"
	GEOMETRYMAT_OVERRIDE_NEXTPASS = 9, # Nextpass Mat
	
}

var material : Material # Only ShaderMaterial types are required for final Update functionality, but in between all types of materials need to be handled.
var material_slot : MaterialSlot # In which slot the material was found
var source_node : Node # On which Node(s) in the level this material was found
var shader_path : String # Is filled later by running fill_shader_paths() only on arrays containing valid ShaderMaterials to reduce overhead.

func convert_to_matlib(mat : Material, mat_slot : MaterialSlot, src_node : Node):
	var converted_to_matlib : ParentShaderUpdater_MatLib = ParentShaderUpdater_MatLib.new() # Wann brauch ich .new???
	#var converted_to_matlib : ParentShaderUpdater_MatLib = {material = null, material_slot = null, shader_path = null} #### Wann brauch ich .new???
	converted_to_matlib.material = mat
	converted_to_matlib.material_slot = mat_slot
	converted_to_matlib.source_node = src_node
	return converted_to_matlib

func convert_to_matlib_append_unique_to_array(mat : Material, mat_slot : MaterialSlot, src_node : Node, array_matlib : Array[ParentShaderUpdater_MatLib], debug_arrayname : String) -> bool:
	return append_unique_matlib_to_array(convert_to_matlib(mat, mat_slot, src_node), array_matlib, debug_arrayname)
	
func append_unique_matlib_to_array(matlib : ParentShaderUpdater_MatLib, array_matlib : Array[ParentShaderUpdater_MatLib], debug_arrayname : String) -> bool:
	var found_duplicate : bool = false
	for index in array_matlib:
		if matlib.material == index.material:
			found_duplicate = true
			print("PSU: Tried adding existing Mat '", matlib.material.resource_path.get_file(), "' to MatLib '", debug_arrayname, "'.")
			return not found_duplicate

	array_matlib.append(matlib)
	print("PSU: Added new Mat '", matlib.material.resource_path.get_file(), "' to MatLib '", debug_arrayname, "'.") ## Soll den Namen der jeweiligen reingefütterten Array printen
	return not found_duplicate

func fill_shader_paths(array_matlib : Array[ParentShaderUpdater_MatLib], debug_arrayname : String) -> bool:
	if array_matlib.size() < 1:
		print("PSU: ERROR: Targeted MatLib '", debug_arrayname, "' doesn't contain any Mats to get Shader_Path from!")
		return false
		
	for index in array_matlib:
		index.shader_path = index.material.shader.resource_path
	return true
