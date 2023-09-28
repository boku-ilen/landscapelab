vec3 heightToNormal(float height,float strength,vec3 vertex,vec3 normal){
    vec3 worldDerivativeX = dFdx(vertex);
    vec3 worldDerivativeY = dFdy(vertex);
	
    vec3 crossX = cross(normal, worldDerivativeX);
    vec3 crossY = cross( worldDerivativeY,normal);	
    float d = dot(worldDerivativeX,crossY);
    float sgn = d < 0.0 ? (-1.0) : 1.0;
    float surface = sgn / max(0.00000000000001192093, abs(d));

    float dHdx = dFdx(height);
    float dHdy = dFdy(height);
    vec3 surfGrad = surface * (dHdx*crossY + dHdy*crossX);
    return normalize(normal - (strength * surfGrad));
}

vec3 flattenNormal(vec3 normal, float s){
	return normalize(mix(normal, vec3(0,0,1),s)); 
}
vec3 normal_strength(vec3 n, float strength)
{
    return vec3(n.rg * strength, mix(1, n.b, clamp(strength,0.0,1.0)));
}
vec3 normal_blend(vec3 A, vec3 B)
{
    return normalize(vec3(A.rg + B.rg, A.b * B.b));
}
vec3 normal_blend2(vec3 A, vec3 B)
{
    vec3 t = A.xyz + vec3(0.0, 0.0, 1.0);
    vec3 u = B.xyz * vec3(-1.0, -1.0, 1.0);
	return (t / t.z) * dot(t, u) - u;
}