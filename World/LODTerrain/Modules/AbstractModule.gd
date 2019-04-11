extends Spatial
class_name Module

#
# All modules which a WorldTile can spawn must inherit from this scene.
# It allows modules to easily access their parent tile.
#

var tile
var modules

var done = false
var ready = false


func _ready():
	if not get_parent() or not get_parent().get_parent():
		print("ERROR: Module is not correctly placed - grandparent must be a WorldTile! (WorldTile -> Modules -> This")
	else:
		tile = get_parent().get_parent()
		modules = get_parent()


func _on_ready():
	"""This function is called as soon as the ready flag is set by calling make_ready().
	It is run in the main thread, which means that it can manipulate resources, instance scenes, etc.
	
	By default, it is empty. It should be implemented by the derived modules.
	"""
	pass


func _process(delta):
	if ready and not done:
		_on_ready()
		_done_loading()


func _done_loading():
	modules.emit_signal("module_done_loading")
	done = true


func make_ready():
	"""Once this function is called, _on_ready() will be run in the main thread.
	This function can be called in a thread to signify that all required resources have been loaded from the server.
	
	Example:
	Load texture from the server in a thread -> call make_ready() -> textures are applied to nodes in _on_ready()
	"""
	ready = true
