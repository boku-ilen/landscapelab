extends ItemList


var current_index := 0


# Called when the node enters the scene tree for the first time.
func _ready():
	for license in Licenses.licenses:
		add_license(Licenses.licenses[license])
		
	Licenses.connect("license_added", self, "add_license")
	Licenses.connect("license_removed", self, "remove_license")
	connect("item_activated", self, "popup_details")


# FIXME: Do we really want to remove signals during runtime? 
func remove_license(name: String):
	pass


func add_license(license: Licenses.License):
	add_item(license.to_string())
	set_item_metadata(current_index, license)
	current_index += 1


func popup_details(idx: int):
	$AcceptDialog.window_title = get_item_metadata(idx).acronym
	$AcceptDialog.dialog_text = get_item_metadata(idx).additional_info
	$AcceptDialog.popup()
