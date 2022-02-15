extends Node

# Date, Time, Season change
signal date_changed
signal time_changed
signal season_changed

# Imaging
signal imaging_add_path_point(position)
signal imaging_set_focus(position)


# settings
## general
signal retranslate

signal asset_show_tooltip
signal asset_hide_tooltip
