@tool
extends Node3D

#
@export var enabled := false:
	set(val):
		enabled = val
		if get_child_count(): set_enabled(val)
# From 0 (invisible rain drops) to 0.5 
@export var drop_size := 0.3 :
	set(val):
		drop_size = val
		if get_child_count(): set_drop_size(val)
# From 0 (no rain) to 1 (very dense rain)
@export var density := 0.0 :
	set(val):
		density = val
		if get_child_count(): set_rain_density(val)
# Cardinal direction of wind as unit vector and wind speed
@export var wind_direction := Vector3(0, 0, 0) :
	set(val):
		wind_direction = val
		if get_child_count(): set_wind(val, wind_speed)
@export var wind_speed := 0.0 :
	set(val):
		wind_speed = val
		if get_child_count(): set_wind(wind_direction, val)
# Determines the extent of
#	the individual rain drops/splashes/ripples
# 	the start sheets (grouped texture of rain)
@export var detailed_radius := 30 :
	set(val):
		detailed_radius = val
		if get_child_count(): set_extents(val, coarse_radius, distance_radius)
# Determines the extent of sheets
@export var coarse_radius := 40 :
	set(val):
		coarse_radius = val
		if get_child_count(): set_extents(detailed_radius, val, distance_radius)
# Determines the extent of distant fog
@export var distance_radius := 100 :
	set(val):
		distance_radius = val
		if get_child_count(): set_extents(detailed_radius, coarse_radius, val)

# This threshold defines wether only individual droplets are visualized or
# entire individual droplets + sheets + foggy billboards
var heavy_rain_threshold := 0.5


func set_enabled(enabled: bool):
	for child in get_children():
		if child is FogVolume:
			child.visible = enabled
		if child is GPUParticles3D:
			child.emitting = enabled
		if child is GPUParticlesCollisionHeightField3D:
			child.heightfield_mask = 5 * float(enabled)


func set_rain_density(_density: float):
	$RainVolumeFog.material.density = _density * 0.03
	$RainDrops.amount = _density * 1000
	$RainSheetStraight.emitting = _density > heavy_rain_threshold
	$RainSheetRound.emitting = _density > heavy_rain_threshold
	$RainSheetStraight.amount = _density * 100
	$RainSheetRound.amount = _density * 100

	$RainSplashes.amount = _density * 500
	$RainSplashes/RainRipples.amount = _density * 500

	$RainDistantFog.emitting = _density > heavy_rain_threshold
	$RainDistantFog.amount = _density * 30


func set_wind(direction: Vector3, speed: float):
	var set_wind_for_material = func(material: ParticleProcessMaterial, direction, speed):
		material.direction = direction.normalized()
		material.linear_accel_min = speed - speed * 0.25
		material.linear_accel_max = speed + speed * 0.25
		material.initial_velocity_min = (speed - speed * 0.25) * 0.5
		material.initial_velocity_max = (speed + speed * 0.25) * 0.5

	set_wind_for_material.call($RainDrops.process_material, direction, speed)
	set_wind_for_material.call($RainSheetStraight.process_material, direction, speed)
	set_wind_for_material.call($RainSheetRound.process_material, direction, speed)


func set_extents(detailed_radius: int, coarse_radius: int, distance_radius: int):
	$RainDrops.process_material.emission_ring_radius = detailed_radius

	$RainSheetStraight.process_material.emission_ring_inner_radius = detailed_radius
	$RainSheetStraight.process_material.emission_ring_radius = coarse_radius

	$RainSheetRound.process_material.emission_ring_inner_radius = detailed_radius
	$RainSheetRound.process_material.emission_ring_radius = coarse_radius

	$RainDistantFog.process_material.emission_ring_inner_radius = distance_radius - distance_radius * 0.3
	$RainDistantFog.process_material.emission_ring_radius = distance_radius + distance_radius * 0.3


func set_drop_size(size):
	$RainDrops.draw_pass_1.size = size
	$RainDrops.trail_lifetime = max(0.1, size / 100)
	
	$RainSheetStraight.material_override.albedo_color.a  = inverse_lerp(0.001, 0.05, size) * 0.2
	$RainSheetRound.material_override.albedo_color.a = inverse_lerp(0.001, 0.05, size) * 0.2
	
	$RainSplashes.process_material.scale_min = size * 10 
	$RainSplashes.process_material.scale_min -= $RainSplashes.process_material.scale_min * 0.05
	$RainSplashes.process_material.scale_max = size * 10
	$RainSplashes.process_material.scale_max += $RainSplashes.process_material.scale_max * 0.05
	
	$RainSplashes/RainRipples.process_material.scale_min = size * 10 
	$RainSplashes/RainRipples.process_material.scale_min -= $RainSplashes/RainRipples.process_material.scale_min * 0.05
	$RainSplashes/RainRipples.process_material.scale_max = size * 10 
	$RainSplashes/RainRipples.process_material.scale_max += $RainSplashes/RainRipples.process_material.scale_max * 0.05
