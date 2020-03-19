extends Node


var styles = [
	Style.new("Realistic"),
	Style.new("Abstract")
]


signal change_style(style_id)


func _ready():
	connect("change_style", self, "_on_change_style")


func _on_change_style(id: int):
	# TODO: This is just a proof of concept of the functionality. Will be removed
	print(styles[id].name)


class Style:
	var name
	
	func _init(name: String):
		self.name = name
