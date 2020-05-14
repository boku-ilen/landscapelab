extends Node

#
# All the signals that are mapped from an input event to a signal
#

# General

signal ui_loaded

# Imaging

signal imaging
signal toggle_imaging_view
signal clear_imaging_path
signal toggle_imaging_recording

# Teleportation

signal set_teleport_mode(boolean)
signal poi_teleport(location_coordinates)

# Settings

# enable and disable debug mode
signal toggle_debug(boolean)


# Tiles

# enable and disable tile updates
signal tile_update_toggle

# enable and disable wireframe drawing
signal wireframe_toggle
