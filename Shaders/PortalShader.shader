shader_type spatial;

uniform sampler2D viewportData;

uniform vec3 color1;
uniform vec3 color2;

void vertex(){
	//MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(CAMERA_MATRIX[0],CAMERA_MATRIX[1],CAMERA_MATRIX[2],WORLD_MATRIX[3]);
	
	
	vec4 i1 = vec4(1.0, 0.0, 0.0, 0.0);
	vec4 i2 = vec4(0.0, 1.0, 0.0, 0.0);
	vec4 i3 = vec4(0.0, 0.0, 1.0, 0.0);
	vec4 i4 = vec4(0.0, 0.0, 0.0, 1.0);
	mat4 m1 = INV_CAMERA_MATRIX;
	mat4 m2 = mat4(CAMERA_MATRIX[0], WORLD_MATRIX[1], WORLD_MATRIX[2], WORLD_MATRIX[3]);
	mat4 m3 = mat4(vec4(WORLD_MATRIX[0][0], 0.0, 0.0, 0.0), i2, i3, i4);
	MODELVIEW_MATRIX = m1 * m2 * m3;
}

float toFrac(float val) {
	return val - float(int(val));
}

float wave(float val) {
	return (sin(val) + 1.0) / 2.0;
}

//450 by 640
const float xSize = 450.0;
const float ySize = 640.0;
const float cx = 0.5;
const float cy = 0.5;
void fragment() {
	vec2 uv = UV;
	ALBEDO.rgb = texture(viewportData, uv).rgb;
	float d1 = UV.x - cx;
	float d2 = UV.y - cy;
	float dist2 = d1 * d1 + d2 * d2;
	if (dist2 > 0.45 * 0.45) {
		ALPHA = 0.0;
	} else {
		ALPHA = 1.0;
	}
	if (dist2 > 0.45 * 0.45 && dist2 <= 0.5 * 0.5) {
		ALPHA = 1.0;
		float progress = 0.0;
		float px = (UV.x * 2.0) - 1.0;
		float py = (UV.y * 2.0) - 1.0;
		if (px == 0.0) {
			px = 0.001;
		}
		
		progress = atan(py / px);
		if (px < 0.0) {
			progress = progress + 3.141592654;
		}
		float frac = wave(TIME * 10.0 + progress * 1.0);
		ALBEDO.rgb = mix(color1, color2, frac);
	}
	//ALBEDO.rgb = mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), UV.x);
}