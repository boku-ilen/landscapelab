float depth_proximity(float dist, vec3 vertex, sampler2D depthtex, vec2 screenuv,mat4 invproj){
	float depth_tex = textureLod(depthtex, screenuv, 0.0).r;
	vec4 depth_world_pos = invproj * vec4(screenuv * 2.0 - 1.0, depth_tex, 1.0);
	depth_world_pos.xyz /= depth_world_pos.w;
	return clamp(1.0 - smoothstep(depth_world_pos.z + dist, depth_world_pos.z, vertex.z), 0.0, 1.0);
}
float depth_linear(sampler2D depthtex, vec2 screenuv,mat4 invproj){
	float depth_tex = textureLod(depthtex,screenuv,0.0).r;
  	vec3 ndc = vec3(screenuv * 2.0 - 1.0, depth_tex);
	vec4 depth_world_pos = invproj * vec4(ndc, 1.0);	
	depth_world_pos.xyz /= depth_world_pos.w;	
	return depth_world_pos.z; 
}
float depth_proximity_z(float dist, float z,vec3 vertex){
	return clamp(1.0 - smoothstep(z + dist, z, vertex.z), 0.0, 1.0);
}

float fresnel(float power,vec3 normal,vec3 view){
	return pow(1.0 - clamp(dot(normal,view), 0.0, 1.0), power);
}

