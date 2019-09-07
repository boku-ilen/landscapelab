extends TextureButton

#
# This button activates/disactivates the energy tooltips 
# with signals and toggles the visibility of the energy 
# details view
#

# Get the "Energy Value"- and "Amount"-label so it can be dynamically changed with update()
var energy_value_label : Label = Label.new()
var assets_amount_label : Label = Label.new()
var target_energy_label : Label = Label.new()

onready var energy_details = get_node("Panel")
onready var requester = get_node("RegularServerRequest")


func _ready():
	# Make the the interval for the assets request in intervals of 2 seconds
	requester.interval = 2 
	requester.set_request("/energy/contribution/" + String(Session.scenario_id) + "/all.json")
	
	_setup_gui()
	
	energy_details.visible = false


func _process(delta):
	var asset_details = requester.get_latest_response()
	
	if not asset_details == null:
		energy_value_label.text = String(asset_details["total_energy_contribution"])
		assets_amount_label.text = "Total placed assets: " + String(asset_details["number_of_assets"])


func _toggled(button_pressed) -> void:

	energy_details.visible = !energy_details.visible

	if self.pressed:
		GlobalSignal.emit_signal("energy_details_enabled")
	else:
		GlobalSignal.emit_signal("energy_details_disabled")


func _setup_gui():
	var container = HBoxContainer.new()
	container.visible = true
	var unit = Label.new()
	
	unit.text = "MW /"
	
	target_energy_label.text = String(Session.get_current_scenario()["energy_requirement_total"])
	
	container.add_child(energy_value_label)
	container.add_child(unit)
	container.add_child(target_energy_label)
	
	get_parent().get_node("Energy Panel").get_node("Energy").add_child(container)
	get_parent().get_node("Energy Panel").get_node("Energy").add_child(assets_amount_label)