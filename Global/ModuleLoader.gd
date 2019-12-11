extends Node


var module_path = Settings.get_setting("lod", "module-path")

var modules: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for module in list_files_in_directory(module_path):
		modules[module] = load(module_path + module)


func get(module_name):
	return modules[module_name]


func list_files_in_directory(path):
	return ["TerrainModule.tscn"]


#func list_files_in_directory(path):
#	var files = []
#	var dir = Directory.new()
#
#	dir.open(path)
#	dir.list_dir_begin(true, true)
#
#	while true:
#		var file = dir.get_next()
#
#		if file == "":
#			break
#
#		files.append(file)
#
#	dir.list_dir_end()
#
#	return files
