extends FileDialog


const PLANT_FILENAME = "plants.csv"
const GROUP_FILENAME = "groups.csv"


func _ready():
	connect("dir_selected", self, "_save")


func _save(selected_path: String):
	Vegetation.save_to_files(selected_path.plus_file(PLANT_FILENAME), selected_path.plus_file(GROUP_FILENAME))
