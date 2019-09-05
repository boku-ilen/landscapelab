extends TextureButton

#
# This button activates/disactivates the energy tooltips 
# with signals and toggles the visibility of the energy 
# details view
#

# The target energy value shows the energy that should optimally be reached, there are three different options:
# General, summer, winter
var target_energy_value : Dictionary
# Get the "Energy Value"- and "Amount"-label so it can be dynamically changed with update()
var energy_value_label : Label
var assets_amount_label : Label
var target_energy_label : Label


func _ready():
	GlobalSignal.connect("asset_removed", self, "_update")
	GlobalSignal.connect("asset_spawned", self, "_update")
	
	energy_value_label = Label.new()
	assets_amount_label = Label.new()
	target_energy_label = Label.new()
	
	_load_target_values()
	_setup_gui()
	
	for child in get_children():
		child.visible = false
	
	_update()
	_update_target_value("")


func _toggled(button_pressed) -> void:

	for child in get_children():
		child.visible = !child.visible

	if self.pressed:
		GlobalSignal.emit_signal("energy_details_enabled")
	else:
		GlobalSignal.emit_signal("energy_details_disabled")


# An update should be called whenever the value changes (new asset spawned, asset removed, etc.)
func _update():
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_update_threaded", []), 30.0)


# Thread the server request
func _update_threaded(data):
	var asset_details = ServerConnection.get_json("/assetpos/energy_contribution/all.json", false)
	energy_value_label.text = String(asset_details["total_energy_contribution"])
	assets_amount_label.text = "Total placed assets: " + String(asset_details["number_of_assets"])


# Changes the target value depending on the season
func _update_target_value(season):
	if season == "summer":
		target_energy_label.text = String(target_energy_value["summer"]) + " MW"
	elif season == "winter": 
		target_energy_label.text = String(target_energy_value["winter"]) + " MW"
	else:
		target_energy_label.text = String(target_energy_value["general"]) + " MW"


func _load_target_values():
	# TODO: We don't have separate values for summer and winter anymore!
	target_energy_value["general"] = Session.get_current_scenario()["energy_requirement_total"]
	target_energy_value["summer"] = Session.get_current_scenario()["energy_requirement_total"]
	target_energy_value["winter"] = Session.get_current_scenario()["energy_requirement_total"]


func _setup_gui():
	var container = HBoxContainer.new()
	container.visible = true
	var unit = Label.new()
	
	unit.text = "MW /"
	
	container.add_child(energy_value_label)
	container.add_child(unit)
	container.add_child(target_energy_label)
	
	get_parent().get_node("Energy Panel").get_node("Energy").add_child(container)
	get_parent().get_node("Energy Panel").get_node("Energy").add_child(assets_amount_label)