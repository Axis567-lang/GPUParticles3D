shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 ray_position;
uniform int blur_strength: hint_range(1,8) = 3;
uniform float blur_falloff: hint_range(1.0, 20.0) = 7.0;    // Qué tan rápido cambia el enfoque.
uniform float blur_near: hint_range(0.0, 100.0) = 20.0;
uniform float blur_far: hint_range(0.0, 250.0) = 200.0;
uniform sampler2D depth_texture : source_color, hint_depth_texture, filter_linear;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

// Configurable Box Blur by Nighteyes -> https://godotshaders.com/shader/configurable-box-blur/
vec3 blur_size(sampler2D tex,vec2 uv, vec2 pixelSize) {
	// Convierte coordenadas UV en coordenadas de píxeles
	vec2 pixel = uv / pixelSize;
	// Calcula el área para aplicar el desenfoque (cuadro de tamaño blur_strength)
	int x_min = max(int(pixel.x) - blur_strength, 0);
	int y_min = max(int(pixel.y) - blur_strength, 0);
	int x_max = min(int(pixel.x) + blur_strength, int(1.0 / pixelSize.x));
	int y_max = min(int(pixel.y) + blur_strength, int(1.0 / pixelSize.y));
	
	// Acumula todos los colores de esa zona
	int count = 0;
	vec3 color = vec3(0.0);
	for(int x = x_min; x <= x_max; x++) {
		for(int y = y_min; y <= y_max; y++) {           
			color += texture(tex, vec2(float(x), float(y)) * pixelSize).rgb;
			count++;
		}
	}
	return color / float(count);
}

void fragment() {
	// rayo <-> cámara
	float dist = distance(CAMERA_POSITION_WORLD, ray_position);
	// Reconstruye la distancia real desde la cámara al pixel actual 
	//  usando la textura de profundidad.
	float depth = texture(depth_texture, SCREEN_UV).r;
	depth = depth * 2.0 - 1.0;
	//  cámara -> pixel
	float z = -PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
	z = z + dist/2.0;
	
	// Calculate clear/blur threshold
	//  rango de tolerancia alrededor de la distancia focal: 
	//   un margen donde se va transicionando entre enfoque y desenfoque.
	float w = dist/blur_falloff;
	//  Usa `smoothstep` para transiciones suaves.
	float dz = dist >= blur_far ? 1.0 : (1.0 - smoothstep(0.001, w, -(z + w)));
	dz *= dist <= blur_near ? 1.0 : smoothstep(0.001, w, -(z - w));
	// Obtiene el color original
	vec3 screen = texture(screen_texture, SCREEN_UV).rgb;
	// y el desenfocado
	vec3 blur = blur_size(screen_texture, SCREEN_UV, 1.0/VIEWPORT_SIZE);
	
	// Combina los dos: si `dz` es 1, se ve nítido; 
	//  si es 0, desenfocado. Se mezcla según la profundidad.
	ALBEDO = mix(blur, screen, dz);
}