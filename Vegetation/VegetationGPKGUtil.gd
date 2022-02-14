extends VegetationUtil
class_name VegetationGPKGUtil


#
# Static utility functions for loading Vegetation objects from GPKG.
# Builds upon VegetationUtil
#


static func create_density_classes_from_gpkg(db) -> Dictionary:
	return ._create_density_classes(GPKGUtil.load_entire_table(db, "Vegetation_Densities"))


static func create_textures_from_gpkg(db, include_types, exclude_types) -> Dictionary:
	return ._create_textures(GPKGUtil.load_entire_table(db, "Vegetation_Textures"), include_types, exclude_types)


static func create_plants_from_gpkg(db, density_classes: Dictionary) -> Dictionary:
	return ._create_plants(GPKGUtil.load_entire_table(db, "Vegetation_Plants"), density_classes)


static func create_groups_from_gpkg(db, plants: Dictionary,
		ground_textures: Dictionary, fade_textures: Dictionary) -> Dictionary:
	return ._create_groups(GPKGUtil.load_entire_table(db, "Vegetation_Group"), plants, ground_textures, fade_textures)


