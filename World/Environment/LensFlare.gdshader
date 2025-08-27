shader_type spatial;
render_mode unshaded, fog_disabled, blend_add;

// Lens flare shader adapted from https://godotshaders.com/shader/lens-flare-shader/
// which was adapted from https://www.shadertoy.com/view/4sX3Rs

uniform vec2 sun_position = vec2(0.0);
uniform vec3 tint = vec3(1.4,1.2,1.0);

uniform float intensity = 1.0;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, filter_linear_mipmap;

vec3 lensflare(vec2 uv,vec2 pos) {
	vec2 main = uv-pos;
	vec2 uvd = uv*(length(uv));

	float ang = atan(main.x,main.y);
	float dist = length(main);
	dist = pow(dist,0.1);

	float f1 = max(0.01-pow(length(uv+1.2*pos),1.9),.0)*7.0;

	float f2 = max(1.0/(1.0+32.0*pow(length(uvd+0.8*pos),2.0)),.0)*00.25;
	float f22 = max(1.0/(1.0+32.0*pow(length(uvd+0.85*pos),2.0)),.0)*00.23;
	float f23 = max(1.0/(1.0+32.0*pow(length(uvd+0.9*pos),2.0)),.0)*00.21;

	vec2 uvx = mix(uv,uvd,-0.5);

	float f4 = max(0.01-pow(length(uvx+0.4*pos),2.4),.0)*6.0;
	float f42 = max(0.01-pow(length(uvx+0.45*pos),2.4),.0)*5.0;
	float f43 = max(0.01-pow(length(uvx+0.5*pos),2.4),.0)*3.0;

	uvx = mix(uv,uvd,-.4);

	float f5 = max(0.01-pow(length(uvx+0.2*pos),5.5),.0)*2.0;
	float f52 = max(0.01-pow(length(uvx+0.4*pos),5.5),.0)*2.0;
	float f53 = max(0.01-pow(length(uvx+0.6*pos),5.5),.0)*2.0;

	uvx = mix(uv,uvd,-0.5);

	float f6 = max(0.01-pow(length(uvx-0.3*pos),1.6),.0)*6.0;
	float f62 = max(0.01-pow(length(uvx-0.325*pos),1.6),.0)*3.0;
	float f63 = max(0.01-pow(length(uvx-0.35*pos),1.6),.0)*5.0;

	vec3 c = vec3(.0);

	c.r+=f2+f4+f5+f6; c.g+=f22+f42+f52+f62; c.b+=f23+f43+f53+f63;
	c = c*1.3 - vec3(length(uvd)*.05);

	// Do not need an artificial sun
	//c+=vec3(f0);

	return c;
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	// Calculate lens flare
	vec2 uv = SCREEN_UV - vec2(0.5);
	vec2 sun = (sun_position.xy) - vec2(0.5);

	vec3 color = tint * max(lensflare(uv, sun.xy), 0.0);

	// Radially read around the edge of the sun to check how much it's covered, based on the depth texture
	// Would be preferable to access a mipmap here, but those don't exist for depth textures :/
	// Likely the best (and more performant) solution would be a quick pre-pass which checks this and passes the result here
	float number_of_good_depth_samples = 0.0;

	for (float way = 0.0; way <= 2.0 * PI; way += PI / 4.0) {
		vec2 offset = vec2(cos(way), sin(way));
		float depth = texture(DEPTH_TEXTURE, ((sun_position.xy + offset * 0.01))).r;
		number_of_good_depth_samples += float(depth <= 0.01);
	}

	color *= mix(0.0, 1.0, smoothstep(0.0, 8.0, number_of_good_depth_samples));

	// Fade out the lens flare as the sun gets out of the camera's view
	color *= clamp(float(1.5 - length(sun)), 0.0, 0.4) * 0.6 * intensity;

	ALBEDO = color;
}