extends PopupMenu


var layer: Layer setget set_layer

onready var color_menu = get_node("ColorMenu")
onready var object_menu = get_node("ObjectMenu")

var layer_config = preload("res://UI/Layers/LayerConfiguration/Misc/LayerConfigurationWindow.tscn")

signal change_color_tag(color)
signal change_object(object_scene)
signal open_menu(which)

var colors = {
	"None": Color(0, 0, 0, 0),
	"Green": Color.green,
	"Red": Color.red,
	"Blue": Color.blue,
	"Yellow": Color.yellow
}


signal translate_to_layer


func set_layer(l):
	layer = l 
	
	if layer is FeatureLayer:
		add_separator()
		_add_submenu("Objects", "ObjectMenu", RenderedObjects.dict, "change_object", self, 1)
		connect("change_object", layer, "object_changed")
	else:
		add_separator()


func _ready():
	connect("index_pressed", self, "_on_item_pressed")
	set_item_metadata(0, "_open_configure_menu")
	set_item_metadata(1, "_translate_to_layer")
	
	_add_submenu("Color Tag", "ColorMenu", colors, "change_color_tag")


func _on_item_pressed(idx: int):
	var what = get_item_metadata(idx)
	
	call(what)


func _open_configure_menu():
	var instance = layer_config.instance()
	add_child(instance)
	instance.layer_popup(Vector2(100,200), layer)
	#instance.specific_layer_ui


func _translate_to_layer():
	emit_signal("translate_to_layer")


func _default_emit(idx: int, corresponding_menu: PopupMenu, sig: String):
	emit_signal(sig, corresponding_menu.get_item_metadata(idx))


# A pretty complex function for adding options for editing layers from the gui.
# In order to be able to load nested dictionaries (or JSONS) without any further effort,
# this function will recursively traverse through all of the hierarchies and make them
# individual menus and submenus. 
# To also give it the possibility of stopping at a certain level of hierarchy, 
# recursion_level can be used. By default (-1) it will just traverse through all possibilites.
# The function_to_connect argument is used for connecting to the wished new function.
func _add_submenu(display_name: String, node_name: String, menu_items, signal_to_emit: String, relative_node: PopupMenu = self, recursion_level: int = -1, recursion_count: int = 0):
	if recursion_count > recursion_level and recursion_level > -1: return
	if not (menu_items is Dictionary or menu_items is Array): return
	
	var current_menu = relative_node.get_node(node_name)
	
	var idx = 0
	for item in menu_items:
		if (menu_items[item] is Dictionary or menu_items[item] is Array) and not recursion_count == recursion_level:
			var new_menu = PopupMenu.new()
			new_menu.name = item
			relative_node.get_node(node_name).add_child(new_menu)
			_add_submenu(item, item, menu_items[item], signal_to_emit, relative_node.get_node(node_name), recursion_level, recursion_count + 1)
			idx += 1
		else:
			current_menu.add_item(item)
			current_menu.set_item_metadata(idx, menu_items[item])
			idx += 1
	

	current_menu.connect("index_pressed", self, "_default_emit", [current_menu, signal_to_emit])

	relative_node.add_submenu_item(display_name, node_name)
