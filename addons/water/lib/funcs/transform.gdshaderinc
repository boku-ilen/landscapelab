vec2 polar_coordinates(vec2 uv, vec2 center)
{
	vec2 dir = uv - center;
	float radius = length(dir) * 2.0;
	float angle = atan(dir.y, dir.x) / TAU; 
	return (vec2(radius, angle)); 
}
vec2 rotation ( vec2 uv, vec2 center, float angle){
	float _ang = radians(angle); 
	mat2 rotation = mat2(
					vec2(cos(_ang), -sin(_ang)), 
					vec2(sin(_ang), cos(_ang))
					);
	uv -= center; 
	uv *= rotation; 
	uv += center; 
	return uv; 				 
}
vec2 scale(vec2 uv, float x, float y)
{
	mat2 scale = mat2(
				vec2(x, 0.0), 
				vec2(0.0, y)
				);
	
	uv -= 0.5;
	uv = uv * scale;
	uv += 0.5;
	return uv;
}