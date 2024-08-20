shader_type particles;

void start() {
	float row = float(INDEX % uint(10));
	float col = float(INDEX / uint(10));
	TRANSFORM[3].xyz = vec3(row, 0.0, col);
}
//
//void process() {
	//TRANSFORM[3].xyz += vec3(1.0) * DELTA;
//}
