extends VegetationUtil
class_name VegetationCSVUtil

#
# Static utility functions for loading Vegetation objects from pre-defined CSV files.
#

static func create_density_classes_from_csv(csv_path: String) -> Dictionary:
	var density_csv = CSVReader.new()
	density_csv.read_csv(csv_path)
	
	return super._create_density_classes(density_csv.get_lines())


static func create_textures_from_csv(csv_path: String, include_types, exclude_types) -> Dictionary:
	var texture_csv = CSVReader.new()
	texture_csv.read_csv(csv_path)
	
	return super._create_textures(texture_csv.get_lines(), include_types, exclude_types)


static func create_plants_from_csv(csv_path: String, density_classes: Dictionary) -> Dictionary:
	var plant_csv = CSVReader.new()
	plant_csv.read_csv(csv_path)
	
	return super._create_plants(plant_csv.get_lines(), density_classes)


static func create_groups_from_csv(csv_path: String, plants: Dictionary,
		ground_textures: Dictionary, fade_textures: Dictionary) -> Dictionary:
	var group_csv = CSVReader.new()
	group_csv.read_csv(csv_path)

	return super._create_groups(group_csv.get_lines(), plants, ground_textures, fade_textures)


static func save_plants_to_csv(plants: Dictionary, csv_path: String):
	# Backup the old file
	if DirAccess.copy_absolute(csv_path, csv_path + ".backup-" + str(Time.get_unix_time_from_system())) != OK:
		logger.error("Couldn't create backup -- didn't save!")
		return
	
	var plant_csv = FileAccess.open(csv_path, FileAccess.WRITE)
	
	if not plant_csv.is_open():
		logger.error("Plants CSV file at %s could not be created or opened for writing"
				% [csv_path])
		return
	
	var headings = "ID,GENERIC_FILENAME,TYPE,SIZE,H_MIN,H_MAX,DENSITY,SPECIES,NAME_DE,NAME_EN,SEASON,STYLE,COLOR,SOURCE,LICENSE,AUTHOR,NOTE,LAB_PLANT_DENSITY,GR-WIDTH,GR-PLANTS_per_HA,PLANTS_per_HA,DENSITY_CLASS"
	plant_csv.store_line(headings)
	
	for plant in plants.values():
		plant_csv.store_csv_line([
			plant.id,
			plant.billboard_path,
			plant.type,
			reverse_parse_size(plant.size_class),
			plant.height_min,
			plant.height_max,
			1.0, # TODO: Remove this old density (from the definition too)
			plant.species,
			plant.name_de,
			plant.name_en,
			reverse_parse_season(plant.season),
			plant.style,
			plant.color,
			plant.source,
			plant.license,
			plant.author,
			plant.note,
			plant.density_ha,
			plant.cluster_width,
			plant.cluster_per_ha,
			plant.plants_per_ha,
			plant.density_class.id
		])


static func save_groups_to_csv(groups: Dictionary, csv_path: String) -> void:
	# Backup the old file
	if DirAccess.copy_absolute(csv_path, csv_path + ".backup-" + str(Time.get_unix_time_from_system())) != OK:
		# TODO: Give a warning to the UI too
		logger.error("Couldn't create backup -- didn't save!")
		return
	
	var group_csv = FileAccess.open(csv_path, FileAccess.WRITE)
	
	if not group_csv.is_open():
		logger.error("Groups CSV file at %s could not be created or opened for writing"
				% [csv_path])
		return
	
	var headings = "LID,LABEL_DE,LABEL_EN,PLANTS,TEXTURE_ID,DISTANCE_MAP_ID"
	group_csv.store_line(headings)
	
	for group in groups.values():
		group_csv.store_csv_line([
			group.id,
			group.name_de,
			group.name_en,
			",".join(PackedStringArray(group.get_plant_ids())),
			group.ground_texture.id,
			group.fade_texture.id if group.fade_texture else null
		])


static func parse_size(size_string: String):
	if size_string == "XS": return Plant.Size.XS
	elif size_string == "S": return Plant.Size.S
	elif size_string == "M": return Plant.Size.M
	elif size_string == "L": return Plant.Size.L
	elif size_string == "XL": return Plant.Size.XL
	else: return null


static func parse_season(season_string: String):
	if season_string == "SPRING": return Plant.Season.SPRING
	elif season_string == "SUMMER": return Plant.Season.SUMMER
	elif season_string == "AUTUMN": return Plant.Season.AUTUMN
	elif season_string == "WINTER": return Plant.Season.WINTER
	else: return null


static func reverse_parse_size(size):
	if size == Plant.Size.XS: return "XS"
	elif size == Plant.Size.S: return "S"
	elif size == Plant.Size.M: return "M"
	elif size == Plant.Size.L: return "L"
	elif size == Plant.Size.XL: return "XL"
	else: return "UNKNOWN"


static func reverse_parse_season(season):
	if season == Plant.Season.SPRING: return "SPRING"
	elif season == Plant.Season.SUMMER: return "SUMMER"
	elif season == Plant.Season.AUTUMN: return "AUTUMN"
	elif season == Plant.Season.WINTER: return "WINTER"
	else: return "UNKNOWN"
