extends SpecificLayerUI


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$RightBox/Button.connect("pressed", self, "_open_profile_editor")


func _open_profile_editor():
	$RightBox/Button/ProfileEditor.popup_centered()
