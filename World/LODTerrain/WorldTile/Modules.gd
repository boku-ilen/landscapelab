extends Spatial

onready var tile = get_parent()

var num_modules : int = 0 # Number of modules this tile has
var num_modules_loaded : int = 0 # Incremented when a module finishes loading

var module_path = Settings.get_setting("lod", "module-path")
var module_scenes = Settings.get_setting("lod", "modules")

signal module_done_loading # Emitted by modules once they've finished loading and are ready to be displayed


func _ready():
	connect("module_done_loading", self, "_on_module_done_loading")
	spawn_modules()
	
	
func spawn_modules():
	var index = 0
	var modules_to_spawn = []
	
	# Get the number of modules and select the modules we will want to spawn
	for mds in module_scenes:
		if index <= tile.lod: # This tile's lod is equal to or greater than the module's requirement -> spawn it
			for md in mds:
				num_modules += 1
				modules_to_spawn.append(load(module_path + md).instance() as Module)
		else:
			break; # We arrived at the higher LODs, which means we can stop now
			
		index += 1
	
	# Spawn the modules we selected previously
	for module in modules_to_spawn:
		add_child(module)


# Called when the module_done_loading signal is emitted.
# If all modules are now done, emits tile_done_loading
func _on_module_done_loading():
	num_modules_loaded += 1
	
	if num_modules_loaded == num_modules:
		tile.emit_signal("tile_done_loading")