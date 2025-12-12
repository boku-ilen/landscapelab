@tool
extends SubViewport


@export_tool_button("Make screenshot") var screenshot_action = make_screenshot


func make_screenshot():
	get_texture().get_image().save_png("res://screenshot.png")
