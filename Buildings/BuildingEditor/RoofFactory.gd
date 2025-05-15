extends Node
class_name RoofFactory

const extent_threshold := 200.
const height_threshold := 15.
const vertex_count_threshold := 16

const flat_roof_scene = preload("res://Buildings/Components/Roofs/FlatRoof.tscn")
const pointed_roof_scene = preload("res://Buildings/Components/Roofs/PointedRoof.tscn")
const saddle_roof_scene = preload("res://Buildings/Components/Roofs/SaddleRoof.tscn")

const roof_materials = {
	RoofBase.TYPES.FLAT: [
		preload("res://Buildings/Components/Roofs/Resources/RoofPaintedMetal.tres")
	],
	RoofBase.TYPES.POINTED: [
		preload("res://Buildings/Components/Roofs/Resources/RoofSlate.tres"),
		preload("res://Buildings/Components/Roofs/Resources/RoofBarrel.tres"),
		preload("res://Buildings/Components/Roofs/Resources/RoofFrench.tres")
	],
	RoofBase.TYPES.SADDLE: [
		preload("res://Buildings/Components/Roofs/Resources/RoofSlate.tres"),
		preload("res://Buildings/Components/Roofs/Resources/RoofBarrel.tres"),
		preload("res://Buildings/Components/Roofs/Resources/RoofFrench.tres")
	]
}


static func prepare_roof(
	layer_composition: LayerComposition, 
	feature, 
	addon_layers,
	addon_objects,
	building_metadata,
	check_roof_type,
	walls_resource):
	
	var roof_material = preload("res://Buildings/Components/Roofs/Resources/RoofSlate.tres")
	var roof: RoofBase
	if layer_composition.render_info is LayerComposition.BuildingRenderInfo:
		var slope = feature.get_attribute(layer_composition.render_info.slope_attribute_name)
		var can_build_roof := false
		
		# In case it is a very tall/big building, a flat roof will be most sensible
		var is_tall = building_metadata.height > height_threshold
		var is_big = building_metadata.extent > extent_threshold
		var is_complex = building_metadata.footprint.size() > vertex_count_threshold
		if is_tall or is_big or is_complex:
			roof = null # Will result in a flatroof (line if roof == null or not can_build_roof)
		elif check_roof_type and walls_resource.prefer_pointed_roof:
			if feature.get_outer_vertices().size() == 5:
				roof = saddle_roof_scene.instantiate().with_data(
					feature.get_id(),
					addon_layers, 
					addon_objects,
					building_metadata)
				roof.set_metadata(building_metadata)
				can_build_roof = true
			elif util.str_to_var_or_default(slope, 20) > 15:
				roof = pointed_roof_scene.instantiate().with_data(
					feature.get_id(),
					addon_layers, 
					addon_objects,
					building_metadata)
				roof.set_metadata(building_metadata)
				can_build_roof = roof.can_build(
					building_metadata.geo_center,feature.get_outer_vertices())
		
		if roof == null or not can_build_roof:
			roof = flat_roof_scene.instantiate().with_data(
				feature.get_id(),
				addon_layers, 
				addon_objects,
				building_metadata)

		var color = Color(
			util.str_to_var_or_default(
				feature.get_attribute(layer_composition.render_info.red_attribute_name), 200) / 255.0,
			util.str_to_var_or_default(
				feature.get_attribute(layer_composition.render_info.green_attribute_name), 130) / 255.0,
			util.str_to_var_or_default(
				feature.get_attribute(layer_composition.render_info.blue_attribute_name), 130) / 255.0
		)

		# Increase contrast and saturation
		color.v *= 0.4
		color.s *= 2.0
		
		var material_candidates = []
		for material in roof_materials[roof.type]:
			if color.h > material.from.h and color.h < material.to.h:
				material_candidates.append(material)
		
		if material_candidates.size():
			roof_material = material_candidates[hash(feature.get_id()) % material_candidates.size()]
		
		roof.color = color
	
		return {"roof": roof, "material": roof_material}


static func set_surface_overrides(roof, roof_material):
	# Surface overrides have to be set after building (otherwise they dont exist)
	if roof_material.material0 != null:
		roof.roof_mesh.material_override = null
		roof.roof_mesh.set_surface_override_material(0, roof_material.material0)
	if roof_material.material1 != null and roof.roof_mesh.get_surface_override_material_count() > 1:
		roof.roof_mesh.set_surface_override_material(1, roof_material.material1)
