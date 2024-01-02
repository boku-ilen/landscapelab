extends MenuButton
class_name MenuButtonExtended

#
# This class is a helper class for more easily creating menusbuttons and their
# corresponding pupops. In order to create a menu for a button, create a Menu object
# inside the button and make sure to check the is_top member variable.
# This will create the first menu that will popup when clicking the button. 
#
# In order to create items for the PopupMenu, use MenuItem objects and reference 
# them in the menu_items member array. MenuItems consist of:
# - a label which defines the displayed text
# - a callable function (anonymous lambda or any other function really)
#		this function will be called once the item is clicked
# - a bool whether it should be checkable
# - a bool whether it should be checked initially
# - an optional icon
#
# To add a submenu, create a menu and add it to the menu_items array


# An item inside a popup menu
class MenuItem:
	var label: String
	# function that will be called once the item is clicked
	var callback: Callable
	# optional
	var checkable: bool
	var checked: bool
	var entry_icon: Texture2D
	
	func _init(_label: String, _callback: Callable, _checkable:=false,
				 _checked:=false, _entry_icon:Texture2D=null):
		label = _label
		entry_icon = _entry_icon
		checkable = _checkable
		checked = _checked
		callback = _callback

# The layout of the menu
class Menu:
	# If it is the primary uppermost menu
	var is_top: bool
	var title: String
	var popup: PopupMenu
	var menu_items: Array
	
	func _init(_is_top: bool, _title: String, _items: Array):
		is_top = _is_top
		title = _title
		menu_items = _items

@onready var top_popup = get_popup()


func _ready():
	for property_dict in get_property_list():
		var property = get(property_dict.name)
		
		# Create the initial menu for the top menu and recursively create sebmenus
		if property is Menu and property.is_top:
			top_popup.name = property.title
			property.popup = top_popup
			create_menu(property)


func create_menu(menu: Menu):
	for i in menu.menu_items.size():
		var menu_item = menu.menu_items[i]
		if menu_item is Menu:
			create_submenu_from_menu_object(menu.popup, menu_item)
			create_menu(menu_item)
		else:
			add_item_func(menu, menu_item, i)
	
	menu.popup.index_pressed.connect(
		func(idx): menu.popup.get_item_metadata(idx).call())


# Create item as configured via MenuItem class
func add_item_func(menu: Menu, menu_item: MenuItem, id: int):
	if menu_item.entry_icon != null: 
		if menu_item.checkable:
			menu.popup.add_icon_check_item(menu_item.entry_icon, menu_item.label, id)
			menu.popup.set_item_checked(id, menu_item.checked)
		else:
			menu.popup.add_icon_item(menu_item.entry_icon, menu_item.label, id)
	else:
		if menu_item.checkable:
			menu.popup.add_check_item(menu_item.label, id)
			menu.popup.set_item_checked(id, menu_item.checked)
		else:
			menu.popup.add_item(menu_item.label, id)
	
	menu.popup.set_item_metadata(id, menu_item.callback)


func create_submenu_from_menu_object(supermenu: Popup, submenu: Menu):
	submenu.popup = PopupMenu.new()
	submenu.popup.name = submenu.title
	
	supermenu.add_child(submenu.popup)
	supermenu.add_submenu_item(submenu.title, submenu.title)
