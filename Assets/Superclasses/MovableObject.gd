extends GroundedSpatial
class_name MoveableObject

#
# A superclass for any movable asset (pv, windmill, etc.).
# Handles the loading of the tooltip.
#

onready var tooltip = get_node("Tooltip3D")

# Called when the node enters the scene tree for the first time.
func _ready():
	# As this is a threaded task and the tooltip needs a text set on creation, a temporary string will be given
	tooltip.set_label_text("loading ...")
	ThreadPool.enqueue_task(ThreadPool.Task.new(self, "_request_energy_value", name), 70.0)


func _request_energy_value(id):
	var energy_value = ServerConnection.get_json("/energy/location/" + id + ".json")
	
	if energy_value != null:
		tooltip.set_label_text(energy_value + " MW")
	else:
		tooltip.set_label_text("unknown MW")
