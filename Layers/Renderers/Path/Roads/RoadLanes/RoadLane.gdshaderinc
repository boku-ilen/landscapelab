// RoadLane variables. REQUIRED
uniform float width = 5.0;
uniform float height = 0.2;
uniform sampler2D road_texture: source_color;
uniform sampler2D damage_texture: source_color;
uniform sampler2D damage_overlay: source_color;
uniform sampler2D damage_opacity: hint_default_black;
uniform sampler2D wear_factor: hint_default_black;
uniform float world_uv_scaling = 0.35;
varying vec3 WORLD_UV;