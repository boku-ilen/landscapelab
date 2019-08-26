extends TextureButton

#
# This button activates/disactivates the energy tooltips 
# with signals and toggles the visibility of the energy 
# details view
#

# Get the "Energy Value"- and "Amount"-label so it can be dynamically changed with update()
var energy_value
var amount


func _ready():
	energy_value = get_parent().get_node("Energy").get_node("Energy Value")
	amount = get_parent().get_node("Energy").get_node("Amount of Assets")
	
	for child in get_children():
		child.visible = false
	
	_update()


func _toggled(button_pressed) -> void:

	for child in get_children():
		child.visible = !child.visible

	if self.pressed:
		GlobalSignal.emit_signal("energy_details_enabled")
	else:
		GlobalSignal.emit_signal("energy_details_disabled")


# An update should be called whenever the value changes (new asset spawned, asset removed, etc.)
func _update():
	var asset_details = ServerConnection.get_json("/assetpos/energy_contribution/all.json")
	energy_value.text = String(asset_details["total_energy_contribution"]) + " MW"
	amount.text = "Total placed assets: " + String(asset_details["number_of_assets"])