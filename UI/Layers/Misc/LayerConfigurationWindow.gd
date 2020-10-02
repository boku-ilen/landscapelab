extends WindowDialog

var layer: Layer
var specific_layer_ui

onready var container = get_node("VBoxContainer")
onready var object_button = get_node("VBoxContainer/HSplitContainer/VBoxContainer2/ObjectDropDown")
onready var objects_popup = get_node("VBoxContainer/HSplitContainer/VBoxContainer2/ObjectDropDown/ObjectsPopup")
onready var type_chooser = get_node("VBoxContainer/HSplitContainer/VBoxContainer2/TypeChooser")
onready var min_size = rect_min_size


func _ready():
	connect("resized", self, "_on_resize")
	object_button.connect("pressed", self, "_pop_objects")
	objects_popup.connect("id_pressed", self, "_test")
	type_chooser.connect("item_selected", self, "_on_type_select")
	
	_add_types()
	
	for object in RenderedObjects.dict:
		_add_submenu(object, object, RenderedObjects.dict[object], "_emit_object_change", objects_popup, 0)


func resize(add: Vector2):
	rect_min_size = min_size + add
	rect_size = rect_min_size


func _on_resize():
	container.rect_size.x = rect_size.x - 75


func _pop_objects():
	objects_popup.popup(Rect2(object_button.rect_global_position, Vector2(80, 40)))


func _emit(idx: int, menu: PopupMenu, sig: String):
	emit_signal(sig, menu.get_item_metadata(idx))


func _add_submenu(display_name: String, node_name: String, menu_items, signal_to_emit: String, current_menu: PopupMenu = objects_popup, recursion_level: int = -1, recursion_count: int = 0):
	if recursion_count > recursion_level and recursion_level > -1: return
	if not (menu_items is Dictionary or menu_items is Array): return
	
	var new_menu = PopupMenu.new()
	new_menu.name = node_name
	current_menu.add_child(new_menu)
	
	var idx = 0
	for item in menu_items:
		if (menu_items[item] is Dictionary or menu_items[item] is Array) and not recursion_count == recursion_level:
			_add_submenu(item, item, menu_items[item], signal_to_emit, new_menu, recursion_level, recursion_count + 1)
			idx += 1
		else:
			new_menu.add_item(item)
			new_menu.set_item_metadata(idx, menu_items[item])
			idx += 1
	
	new_menu.connect("index_pressed", self, "_emit", [new_menu, signal_to_emit])
	current_menu.add_submenu_item(display_name, node_name)


func _add_types():
	for type in Layer.RenderType:
		type_chooser.add_item(type)


# TODO: This shouldnt be all upercase anyways, maybe move this functionality
func _on_type_select(idx: int):
	var type: String = type_chooser.get_item_text(idx)
	type = type.substr(0, 1) + type.substr(1).to_lower()
	
	if specific_layer_ui != null:
		container.remove_child(specific_layer_ui)
	
	specific_layer_ui = load("res://UI/Layers/Misc/SpecificLayerUI/%sLayer.tscn" % type).instance()
	container.add_child(specific_layer_ui)
	container.move_child(specific_layer_ui, 1)
	
	resize(Vector2(0, specific_layer_ui.rect_size.y))
