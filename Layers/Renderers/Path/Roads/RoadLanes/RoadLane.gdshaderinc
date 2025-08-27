// RoadLane variables. REQUIRED
uniform float width = 5.0;
uniform float height = 0.2;

uniform sampler2D road_texture: source_color;
uniform sampler2D road_normals: hint_normal;

uniform sampler2D damage_texture: source_color;
uniform sampler2D damage_normals: hint_normal;

uniform sampler2D damage_overlay: source_color;
uniform sampler2D damage_overlay_normals: hint_normal;

uniform sampler2D damage_opacity: hint_default_black;
uniform sampler2D wear_factor: hint_default_black;
uniform vec3 world_uv_scaling = vec3(0.4, 1.0, -0.4);
varying vec3 WORLD_UV;