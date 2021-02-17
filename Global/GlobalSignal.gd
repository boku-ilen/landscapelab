extends Node

# FIXME: Remove many old signals
# We want to avoid this as much as possible, maybe fully?

# World
signal cursor_click(world_position)
signal game_started

#
# GUI emitted signals
# 

# Date, Time, Season change
signal date_changed
signal time_changed
signal season_changed

# Minimap control
signal toggle_follow_mode
signal miniview_close
signal miniview_map
signal miniview_switch
signal miniview_3rd
signal miniview_1st

# MinimapIcon resize notification
signal minimap_icon_resize(new_zoom, minimap_status)
signal initiate_minimap_icon_resize(new_zoom, initiator)
signal request_minimap_icon_resize

# special signals to notify the UI what the missing scene is now
signal missing_map
signal missing_3rd
signal missing_1st

# hide/show all perspective switching and handling buttons
signal hide_perspective_controls
signal show_perspective_controls

# Imaging
signal imaging_add_path_point(position)
signal imaging_set_focus(position)

# Perspective handling
signal main_perspective_active(is_active)

# signal the ui to show the miniview again
signal miniview_show

# control source of input of new items
signal sync_moving_assets
signal input_controller
signal stop_sync_moving_assets
# signal for the ui_controller, when in the list a typ is selected the accoding editable assets should be loaded
signal selected_asset_type(type)
# signals to set the itemID for the itemSpawner
# first one is needed to get the item id in the godot itemList
signal changed_item_to_spawn(item_id)
# second one is the saved according id in the json-file saved as metadata of the listitem
signal changed_asset_id(json_item_id)

## reset (delete) all tiles
signal reset_tiles

## something in the overlay render layer changed so it should be redrawn
signal overlay_updated

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

# settings
## general
signal retranslate

## visual settings
signal third_person_toggle_render_layer(layer_id)


# Teleportation
signal teleported

# Assets
signal asset_spawned
signal asset_removed
signal asset_show_tooltip
signal asset_hide_tooltip
signal toggle_asset_debug_color(asset_type_id, should_color)
