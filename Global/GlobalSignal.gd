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
signal teleport

# MinimapIcon resize notification
signal minimap_icon_resize(new_zoom, minimap_status)
signal initiate_minimap_icon_resize(new_zoom, initiator)
signal request_minimap_icon_resize

# special signals to notify the UI what the missing scene is now
signal missing_map
signal missing_3rd
signal missing_1st

# signal the ui to show the miniview again
signal miniview_show

# control source of input of new items
signal input_lego
signal input_controller
signal input_disabled
# signal for the ui_controller, when in the list a typ is selected the accoding editable assets should be loaded
signal selected_asset_type(type)
# signals to set the itemID for the itemSpawner
# first one is needed to get the item id in the godot itemList
signal changed_item_to_spawn(item_id)
# second one is the saved according id in the json-file saved as metadata of the listitem
signal changed_asset_id(json_item_id)

# enable and disable debug mode
signal debug_enable
signal debug_disable

# enable and disable wireframe drawing
signal wireframe_toggle

# enable and disable vr mode
signal vr_enable
signal vr_disable

# set the tracking modes
signal tracking_start
signal tracking_pause
signal tracking_stop

# energy details mode (incl. tooltips)
signal energy_details_enabled
signal energy_details_disabled