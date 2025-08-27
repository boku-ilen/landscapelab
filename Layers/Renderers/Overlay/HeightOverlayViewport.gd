extends OverlayViewport


func _ready():
	super._ready()
	
	# TODO: Check position of changed overlay and only update if overlaps
	HeightOverlay.updated.connect(update)
