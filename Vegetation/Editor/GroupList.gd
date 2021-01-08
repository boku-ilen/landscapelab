extends ItemList


var group_csv_path = "/home/karl/Downloads/groups.csv"


# Called when the node enters the scene tree for the first time.
func _ready():
	_create_groups_from_csv()
	_build_list()


func _build_list():
	for group in Vegetation.groups.values():
		var item_id = get_item_count()
		add_item(str(group.id) + ": " + group.name)
		set_item_metadata(item_id, group)


func _create_groups_from_csv() -> void:
	var group_csv = File.new()
	group_csv.open(group_csv_path, File.READ)
	
	if not group_csv.is_open():
		logger.error("Groups CSV file does not exist, expected it at %s"
				 % [group_csv_path])
		return
	
	var headings = group_csv.get_csv_line()
	
	#for i in range(100):
	while !group_csv.eof_reached():
		# Format:
		# ID	FILE	TYPE	SIZE	SPECIES	NAME_DE	NAME_EN	SEASON	SOURCE	LICENSE	AUTHOR	NOTE
		var csv = group_csv.get_csv_line()
		
		var id = csv[7]
		var name_en = csv[5]
		
		if id == "": continue
		
		var group = Vegetation.Phytocoenosis.new(id, name_en)
		
		Vegetation.add_group(group)
	
	Vegetation.groups
