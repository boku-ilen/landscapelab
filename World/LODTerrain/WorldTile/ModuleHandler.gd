extends Spatial
class_name ModuleHandler

#
# This scene is part of the WorldTile. It is responsible for spawning
# the modules that this WorldTile should have based on the settings.
#

var tile

var num_modules : int = 0 # Number of modules this tile has
var num_modules_loaded : int = 0 # Incremented when a module finishes loading
var num_modules_to_be_displayed : int = 0 # Incremented when a module wants to be displayed

var module_scenes = Settings.get_setting("lod", "modules")

# Emitted once all modules have emitted module_done_loading
signal all_modules_done_loading


func init(data_with_tile):
	self.tile = data_with_tile[0]

	spawn_modules()
	

# Loads all modules defined for (up to) this LOD in the settings and instances them as children.
func spawn_modules():
	visible = false
	
	var index = 0
	var modules_to_spawn = []
	
	# Get the number of modules and select the modules we will want to spawn
	for mds in module_scenes:
		if index <= tile.lod: # This tile's lod is equal to or greater than the module's requirement -> spawn it
			for md in mds:
				if md.begins_with("-"):
					modules_to_spawn.erase(md.substr(1, md.length() - 1))
					num_modules -= 1
				else:
					modules_to_spawn.append(md)
					num_modules += 1
		else:
			break; # We arrived at the higher LODs, which means we can stop now
			
		index += 1
	
	# Spawn the modules we selected previously
	for module in modules_to_spawn:
		var instance = ModuleLoader.get_instance(module) as Module
		
		instance.connect("module_done_loading", self, "_on_module_done_loading", [instance])
		instance.connect("module_to_be_displayed", self, "_on_module_to_be_displayed", [instance])
		
		instance.init(tile)


# Called when the module_done_loading signal is emitted.
# If all modules are now done, emits tile_done_loading
func _on_module_done_loading(array_with_module):
	num_modules_loaded += 1
	
	add_child(array_with_module)
	
	if num_modules_loaded == num_modules:
		emit_signal("all_modules_done_loading")
		tile.done_loading = true
		
		
# Called when the module_to_be_displayed signal is emitted.
# If all modules are now done, emits tile_to_be_displayed
func _on_module_to_be_displayed(array_with_module):
	num_modules_to_be_displayed += 1
	
	if num_modules_to_be_displayed == num_modules:
		visible = true
		tile.emit_signal("tile_to_be_displayed")
