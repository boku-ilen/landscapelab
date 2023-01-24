shader_type spatial;

uniform sampler2D asphalt: source_color;

const float outer_line_width = 0.03;
const float outer_line_offset = 0.05;
const float outer_line_length = 40.0;
const float outer_line_frequency = 60.0;

const float inner_line_width = 0.04;
const float inner_line_length = 12.0;
const float inner_line_frequency = 40.0;

const float inner_lines = 1.0;

uniform int number_of_lanes = 1;
uniform int lane_types[20];
uniform float lane_widths[20];

uniform bool left_bike_on_road = false;
uniform bool right_bike_on_road = false;

varying vec3 worldpos;


float map_to_range(float value, float old_from, float old_to, float new_from, float new_to){
	return new_from + ((new_to - new_from) / (old_to - old_from)) * (value - old_from);
}

bool inside_line(float value, float width , float position){
	return value > position - width / 2.0 && value < position + width / 2.0;
}

vec3 road_lane(vec2 uv, vec3 color) {
	// Left outer line
	if (inside_line(uv.y, outer_line_width, outer_line_offset)){
		if (left_bike_on_road){
			if (mod(uv.x, outer_line_frequency) < outer_line_length){
				color *= 5.0;
			}
		}
		else {
			color *= 5.0;
		}
	}
	// Right outer line
	if (inside_line(uv.y, outer_line_width, 1.0 - outer_line_offset)){
		if (right_bike_on_road){
			if (mod(uv.x, outer_line_frequency) < outer_line_length){
				color *= 5.0;
			}
		}
		else {
			color *= 5.0;
		}
	}
	
	float offset = outer_line_width + outer_line_offset / 2.0;
	float lane_width = ((1.0 - 2.0 * offset) - inner_line_width * inner_lines) / (inner_lines + 1.0);
	
	
	offset += lane_width / 2.0;
	if (uv.y > offset && uv.y < 1.0 - offset){
		// TODO: Mapping uv here results in different line widths returned from `inside_line()` 
		uv.y = map_to_range(uv.y, offset, 1.0 - offset, 0.0, 1.0);
		uv.y *= inner_lines;
		if (inside_line(fract(uv.y), inner_line_width * inner_lines, 0.5)) {
			if (mod(uv.x, inner_line_frequency) < inner_line_length){
				color *= 5.0;
			}
		}
	}
	
	return color;
}

vec3 bike_lane(vec2 uv, float width, vec3 color, int lane){
	// Left outer line
	if (inside_line(uv.y, outer_line_width, outer_line_offset)){
		color = vec3(1.0);
	}
	// Right outer line
	if (inside_line(uv.y, outer_line_width, 1.0 - outer_line_offset)){
		color = vec3(1.0);
	}
	
	return color;
}

vec3 pedestrian_lane(vec2 uv, float width, vec3 color, int lane){
	return color;
}

vec3 bike_on_road(vec2 uv, float width, vec3 color, int lane){
	if(uv.y > 0.0 && uv.y < 1.0){
		color = vec3(214.0 / 255.0, 118.0 / 255.0, 118.0 / 255.0);
	}
	return color;
}

void vertex()
{
	worldpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * 0.35;
}

void fragment() {
	vec3 color = texture(asphalt, worldpos.xz).rgb;
	
	for(int i = 0; i < number_of_lanes; i++){
		vec2 uv = UV * (float(number_of_lanes) * 2.0 + 6.0) - float(i);
		// Car
		if(lane_types[i] == 0){
			color = road_lane(uv, color);
		}
		// Bike
		else if(lane_types[i] == 1){
			color = bike_lane(uv, lane_widths[i], color, i);
		}
		// Pedestrian
		else if(lane_types[i] == 2){
			if(uv.y > 0.0 && uv.y < 1.0){
				color = pedestrian_lane(uv, lane_widths[i], color, i);
			}
		}
		// Parking
		else if(lane_types[i] == 3){
			if(uv.y > 0.0 && uv.y < 1.0){
				color = vec3(0.1, 0.1, 0.4);
			}
		}
		// Bike on Road
		else if(lane_types[i] == 4){
			color = bike_on_road(uv, lane_widths[i], color, i);
		}
		// Curbside
		else if(lane_types[i] == 10){
			if(uv.y > 0.0 && uv.y < 1.0){
				color = vec3(0.4);
			}
		}
		
	}
	
	ALBEDO = min(color, vec3(1.0,1.0, 1.0));
}

