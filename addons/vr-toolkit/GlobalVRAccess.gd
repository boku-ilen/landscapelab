extends Node


var controller_id_dict: Dictionary
var vr_menus: Array
var object_menu: Node

var prefix = "res://demo/InteractableObjects"
var tool_dict: Dictionary = {
		"PewPew": [prefix.plus_file("PewPew/PewPew.tscn"), false],
		"Ball": [prefix.plus_file("Ball/Ball.tscn"), false],
		"Compass": [prefix.plus_file("Compass/Compass.tscn"), false],
		"GuiObject": [prefix.plus_file("GuiObject/GuiObject.tscn"), false]
	}
