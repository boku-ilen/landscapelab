// Adapted from https://stackoverflow.com/questions/9234724/how-to-change-hue-of-a-texture-with-glsl
const vec3  kRGBToYPrime = vec3 (0.299, 0.587, 0.114);
const vec3  kRGBToI      = vec3 (0.596, -0.275, -0.321);
const vec3  kRGBToQ      = vec3 (0.212, -0.523, 0.311);

const vec3  kYIQToR   = vec3 (1.0, 0.956, 0.621);
const vec3  kYIQToG   = vec3 (1.0, -0.272, -0.647);
const vec3  kYIQToB   = vec3 (1.0, -1.107, 1.704);

vec3 RGBtoHCY(vec3 color) {
    // Convert to YIQ
    float   YPrime  = dot (color, kRGBToYPrime);
    float   I      = dot (color, kRGBToI);
    float   Q      = dot (color, kRGBToQ);

    // Calculate the hue and chroma
    float   hue     = atan (Q, I);
    float   chroma  = sqrt (I * I + Q * Q);
	
	return vec3(hue, chroma, YPrime);
}

vec3 HCYtoRGB(vec3 hcy) {
	// Convert back to YIQ
    float Q = hcy.y * sin (hcy.x);
    float I = hcy.y * cos (hcy.x);

    // Convert back to RGB
    vec3 yIQ = vec3 (hcy.z, I, Q);
	vec3 color;
    color.r = dot (yIQ, kYIQToR);
    color.g = dot (yIQ, kYIQToG);
    color.b = dot (yIQ, kYIQToB);
	
	return color;
}
