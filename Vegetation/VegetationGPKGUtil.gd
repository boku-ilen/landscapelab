extends VegetationUtil
class_name VegetationGPKGUtil


#
# Static utility functions for loading Vegetation objects from GPKG.
# Builds upon VegetationUtil
#


static func create_density_classes_from_gpkg(db) -> Dictionary:
	return super._create_density_classes(db.select_rows("Vegetation_Densities", "", ["*"]).duplicate())


static func create_textures_from_gpkg(db, include_types, exclude_types) -> Dictionary:
	return super._create_textures(db.select_rows("Vegetation_Textures", "", ["*"]).duplicate(), 
								include_types, exclude_types)


static func create_plants_from_gpkg(db, density_classes: Dictionary) -> Dictionary:
	return super._create_plants(db.select_rows("Vegetation_Plants", "", ["*"]).duplicate(), 
								density_classes)


static func create_groups_from_gpkg(db, plants: Dictionary,
		ground_textures: Dictionary, fade_textures: Dictionary) -> Dictionary:
	return super._create_groups(db.select_rows("Vegetation_Group", "", ["*"]).duplicate(), 
								plants, ground_textures, fade_textures)


