extends Node

#
# GUI emitted signals
# 

# Date, Time, Season change
signal date_changed
signal time_changed
signal season_changed

# Minimap control
signal minimap_zoom_in
signal minimap_zoom_out
signal toggle_follow_mode
signal miniview_close
signal miniview_map
signal miniview_switch
signal miniview_3rd
signal miniview_1st

# special signals to notify the UI what the missing scene is now
signal missing_map
signal missing_3rd
signal missing_1st

# signal the ui to show the miniview again
signal miniview_show
