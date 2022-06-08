extends Control


export var layer_renderers_path: NodePath
onready var layer_renderers = get_node(layer_renderers_path)


func _ready():
	visible = false
	
	layer_renderers.connect("loading_started", self, "_on_loading_started")
	layer_renderers.connect("loading_finished", self, "_on_loading_finished")


func _on_loading_started():
	visible = true


func _on_loading_finished():
	visible = false
