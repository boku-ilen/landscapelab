extends GroundedSpatial
class_name MoveableObject

#
# A superclass for any movable asset (pv, windmill, etc.).
# Handles the loading of the tooltip.
#

onready var tooltip = get_node("Tooltip3D")

# Called when the node enters the scene tree for the first time.
func _ready():
	if tooltip:
		# As this is a threaded task and the tooltip needs a text set on creation, a temporary string will be given
		tooltip.set_label_text("loading ...")
		ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_request_energy_value", [name]), 70.0)


func _request_energy_value(data):
	# FIXME: in this case we want to abstract the game logic anyway
	var energy_value = "" # ServerConnection.get_json("/energy/location/%s.json" % [data[0]])
	
	if energy_value and energy_value.has("energy_production"):
		# rounded energy value of asset 
		var energy_production = String(int(round(energy_value["energy_production"])))
		tooltip.set_label_text("%s MWh/a" % energy_production)
	else:
		tooltip.set_label_text("unknown MWh/a")
