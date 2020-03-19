extends Node


var styles = [
	Style.new("Realistic"),
	Style.new("Abstract")
]


signal change_style(style)

var current_style: Style


func _ready():
	connect("change_style", self, "_on_change_style")


func _on_change_style(style: Style):
	current_style = style


class Style:
	var name
	
	func _init(name: String):
		self.name = name
