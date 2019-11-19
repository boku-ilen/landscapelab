extends Spatial

#
# This scene is part of the WorldTile. It is responsible for spawning
# the modules that this WorldTile should have based on the settings.
#

onready var tile = get_parent()

var num_modules : int = 0 # Number of modules this tile has
var num_modules_loaded : int = 0 # Incremented when a module finishes loading
var num_modules_to_be_displayed : int = 0 # Incremented when a module wants to be displayed

var module_path = Settings.get_setting("lod", "module-path")
var module_scenes = Settings.get_setting("lod", "modules")

# Emitted by modules once they've finished loading
signal module_done_loading

# Emitted by modules once they want to be displayed (usually a short time after they're done loading)
signal module_to_be_displayed


func _ready():
	# FIXME: This doesn't belong here, it's logic for the WorldTile. However, it needs
	#  to be done before spawn_modules() happens. We might want to do spawn_modules after
	#  WorldTile is done initializing using a signal.
	#  (_ready() are called from the childmost tile upwards)
	# Adapt the subdivision so that detail increases more gradually (not 2x per split)
	#  because the DHM isn't detailed enough to show that much detail, and we get steps
	#  if the subdivision gets too high on high LOD tiles.
	tile.subdiv = int(tile.subdiv / pow(2, (tile.lod / 4)))
	
	# We add 2 to subdiv and increase the size by the added squares for the skirt around the mesh (which fills gaps
	# where things don't match up)
	tile.size_with_skirt = tile.size + (2.0/(tile.subdiv + 1.0)) * tile.size
	
	connect("module_done_loading", self, "_on_module_done_loading")
	connect("module_to_be_displayed", self, "_on_module_to_be_displayed")
	spawn_modules()
	

# Loads all modules defined for (up to) this LOD in the settings and instances them as children.
func spawn_modules():
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
		var instance = load(module_path + module).instance()
		add_child(instance)


# Called when the module_done_loading signal is emitted.
# If all modules are now done, emits tile_done_loading
func _on_module_done_loading():
	num_modules_loaded += 1
	
	if num_modules_loaded == num_modules:
		tile.emit_signal("tile_done_loading")
		tile.done_loading = true
		
		
# Called when the module_to_be_displayed signal is emitted.
# If all modules are now done, emits tile_to_be_displayed
func _on_module_to_be_displayed():
	num_modules_to_be_displayed += 1
	
	if num_modules_to_be_displayed == num_modules:
		tile.emit_signal("tile_to_be_displayed")
