#!/bin/bash

read -e -p "Path to GeoPackage: " gpkg_relative

# Turn that into a full path
gpkg_full=$(pwd)/$gpkg_relative

gpkg_line="gpkg-path=\"${gpkg_full}\""

# Escape slashes
gpkg_line=${gpkg_line//\//\\/}

sed "2s/.*/${gpkg_line}/" configuration.ini > ${HOME}/.local/share/godot/app_userdata/LandscapeLab\!/configuration.ini
