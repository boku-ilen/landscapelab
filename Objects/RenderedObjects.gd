extends Node

#
# This Object saves all the possible Objects that can be loaded for an Object-Layer
# (or ConnectedObject-Layer) via key-value, where the value will be the according path
# to a PackedScene
#

var dict = {
	"EnergyProduction": {
		"WindTurbine": {
			"Scene": null,
			"Types": [
				Layer.RenderType.OBJECT
			]
		},
		"PhotovoltiacPlant": {
			"Scene": null,
			"Types": [
				Layer.RenderType.OBJECT
			]
		}
	},
	"Vegetation": {
		"Chestnut": {
			"Scene": null,
			"Types": [
				Layer.RenderType.OBJECT
			]
		}
	},
	"Leisure": {
		"Bench": {
			"Scene": null,
			"Types": [
				Layer.RenderType.OBJECT
			]
		},
		"Swing": {
			"Scene": null,
			"Types": [
				Layer.RenderType.OBJECT
			]
		},
		"Slide": {
			"Scene": null,
			"Types": [
				Layer.RenderType.OBJECT
			]
		}
	},
	"Traffic": {
		"StopSign": {
			"Scene": null,
			"Types": [
				Layer.RenderType.OBJECT
			]
		},
		"StreetLamp": {
			"Scene": null,
			"Types": [
				Layer.RenderType.OBJECT
			]
		},
		"Street": {
			"Scene": null,
			"Types": [
				Layer.RenderType.OBJECT,
				Layer.RenderType.CONNECTED_OBJECT
			]
		},
		"Railway": {
			"Scene": null,
			"Types": [
				Layer.RenderType.OBJECT,
				Layer.RenderType.CONNECTED_OBJECT
			]
		},
	},
	"Industry": {
		"Smokestack": null,
		"Silo": null,
	},
	"Construction": {
		"Crane": null,
	},
	"Boundary": {
		"ChainLinkFence": null,
		"WoodenFence": null,
		"Wall": null
	}, 
}


func filter_objects_for_type(type, dictionary = dict, filtered: Dictionary = {}):
	if not dict is Dictionary: return
	 
	for item in dict:
		if dict[item] != type:
			filter_objects_for_type(type, dict[item])
			
	return filtered
