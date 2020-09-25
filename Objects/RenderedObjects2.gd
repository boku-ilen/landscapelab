extends Object

#
# This Object saves all the possible Objects that can be loaded for an Object-Layer
# (or ConnectedObject-Layer) via key-value, where the value will be the according path
# to a PackedScene
#

var test = "THIS AND THAT"

var dict = {
	"EnergyProduction": {
		"WindTurbine": null,
		"PhotovoltiacPlant": null
	},
	"Vegetation": {
		"Chestnut": null
	},
	"Leisure": {
		"Bench": null,
		"Swing": null,
		"Slide": null
	},
	"Traffic": {
		"StopSign": null,
		"StreetLamp": null,
		"Street": null,
		"Railway": null
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
	}
}
