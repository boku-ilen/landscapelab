vec3 screen(vec3 base, vec3 blend){
	return 1.0 - (1.0 - base) * (1.0 - blend);
}
vec3 multiply(vec3 base, vec3 blend){
	return base * blend;
}
vec3 overlay(vec3 base, vec3 blend){
	vec3 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}
vec3 soft_light(vec3 base, vec3 blend){
	vec3 limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}
vec3 darken(vec3 base, vec3 blend){
	return min(base, blend);
}
vec3 color_dodge(vec3 base, vec3 blend){
	return base / (1.0 - blend);
}
vec3 linear_burn (vec3 base, vec3 blend)
{
	return base + blend - 1.0;
}



