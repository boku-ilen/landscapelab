extends SubViewportContainer


var pos_manager: PositionManager :
	get:
		return pos_manager
	set(new_manager):
		pos_manager = new_manager
		$SubViewport/GeoLayerRenderers.pos_manager = new_manager
