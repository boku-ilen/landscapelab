extends Node


var testclass = ParentShaderUpdater_MatLib.new()
var testarray : Array[ParentShaderUpdater_MatLib]
#var testarray : Array[ParentShaderUpdater_MatLib.SingleMatLib] = Array[ParentShaderUpdater_MatLib.SingleMatLib]
var testarray2 : Array[ParentShaderUpdater_MatLib]

func _input(event):
	if event.is_action_pressed("parent_shader_updater"):
		_manual_update_chain()
		
func _manual_update_chain():
	var parent = get_parent()
	var getted_mat_1 = parent.material_override
	var getted_mat_2 = parent.get_surface_override_material(0)
	print(testclass.fill_shader_paths(testarray))
	#testarray.resize(12)
	testclass.convert_to_matlib_append_unique(getted_mat_1, ParentShaderUpdater_MatLib.CurrentMaterialSlot.GEOMETRYMAT_OVERRIDE, testarray)
	testclass.convert_to_matlib_append_unique(getted_mat_2, ParentShaderUpdater_MatLib.CurrentMaterialSlot.SURFACEMAT_OVERRIDE, testarray)
	#print(testarray)
	#testclass.fill_shader_paths(testarray)
#
	#for index in testarray:
		#testclass.append_unique_to_matlib(index, testarray2)
	#
