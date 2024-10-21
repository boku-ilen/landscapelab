class_name ParentShaderUpdater_MatLib extends Object

# Tracks in which usage slot the material was found - for debug printing. ### But should not appear as CONSTANT in the Arrays
enum CurrentMaterialSlot {
	CANVASITEMMAT = 0, # Mat is assigned on CanvasItem # NOT YET IMPLEMENTED, MAYBE NOT NECESSARY
	SURFACEMAT = 1, # Low priority: property "material", only used if no SurfaceMat Override exists for that slot
	SURFACEMAT_OVERRIDE = 2,  # Medium priority: property "surface_material_override"
	GEOMETRYMAT_OVERRIDE = 3, # High priority: property "material_override"
	PARTICLEPROCESSMAT = 4, # Additional type found on GPU particles
}

var material : Material # Only ShaderMaterial types are required for final Update functionality, but in between all types of materials need to be handled.
var material_slot : CurrentMaterialSlot # In which slot the material was found
var shader_path : String # Is filled later by running fill_shader_paths() only on arrays containing valid ShaderMaterials to reduce overhead.

func convert_to_matlib_append_unique(in_material : Material, in_material_slot : CurrentMaterialSlot, dest_matlib : Array[ParentShaderUpdater_MatLib]) -> bool:
	var converted_to_matlib = ParentShaderUpdater_MatLib.new() # Wann brauch ich .new???
	#var converted_to_matlib : ParentShaderUpdater_MatLib = {material = null, material_slot = null, shader_path = null} #### Wann brauch ich .new???
	converted_to_matlib.material = in_material
	converted_to_matlib.material_slot = in_material_slot
	return append_unique_to_matlib(converted_to_matlib, dest_matlib)
	
func append_unique_to_matlib(in_matlib : ParentShaderUpdater_MatLib, dest_matlib : Array[ParentShaderUpdater_MatLib]) -> bool:
	var found_duplicate : bool = false
	for index in dest_matlib:
		if in_matlib.material == index.material:
			found_duplicate = true
			print("Tried adding already existing Mat '", in_matlib.material.resource_path.get_file(), "' to MatLib.")
			return not found_duplicate

	dest_matlib.append(in_matlib)
	print("PSU: Added new Mat '", in_matlib.material.resource_path.get_file(), "' to MatLib '", self, "'.")
	return not found_duplicate

func fill_shader_paths(dest_matlib : Array[ParentShaderUpdater_MatLib]) -> bool:
	if dest_matlib.size() < 1:
		print("PSU: ERROR: Targeted MatLib doesn't contain any Mats to get Shader_Path from!")
		return false
		
	for index in dest_matlib:
		index.shader_path = index.material.shader.resource_path
	return true
