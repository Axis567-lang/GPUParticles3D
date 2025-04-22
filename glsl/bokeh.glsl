#[compute]
#version 450

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(rgba16f, binding = 0, set = 0) uniform image2D screen_tex;
layout(binding = 0, set = 1) uniform sampler2D depth_tex;

layout(push_constant, std430) uniform Params {
    vec2 screen_size;
    // calculate depth no lineal coords to view coords
    float inv_proj_2w;
    float inv_proj_3w;
} pms;

const vec2 offset = vec2(0.0001);
const float sample_size = 5.0;

// ----------------------------------------------------
#define DISPLAY_GAMMA 1.8

#define GOLDEN_ANGLE 2.39996323
#define MAX_BLUR_SIZE 20.0
#define RAD_SCALE 0.1	// Smaller = nicer blur, larger = faster
#define uFar 10.0	// puedes cambiarlo desde push constants si prefiereS
// ----------------------------------------------------

// ----------------------------------------------------
float get_blur_size(float depth, float focus_point, float focus_scale) {
	float coc = clamp((1.0 / focus_point - 1.0 / depth) * focus_scale, -1.0, 1.0);
	return abs(coc) * MAX_BLUR_SIZE;
}
// ----------------------------------------------------

// ----------------------------------------------------
void main() {
	// Convierte la posición global del hilo de cómputo a coordenadas de pixel (x, y)
	ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);

	// Obtiene el tamaño total de la pantalla desde los push constants
	vec2 size = pms.screen_size;

	// Si el pixel está fuera de los límites, termina la ejecución del hilo
	if (pixel.x >= size.x || pixel.y >= size.y) return;

	// Normaliza las coordenadas del pixel para obtener UV (entre 0 y 1)
	vec2 uv = vec2(pixel) / size;

	// Calcula el tamaño de cada texel (pixel) en UV
	vec2 texel_size = 1.0 / size;

	// Obtiene la profundidad desde la textura de profundidad
	float depth = texture(depth_tex, uv).r;

	// Convierte la profundidad no lineal a profundidad lineal en coordenadas de vista
	float linear_depth = 1. / (depth * pms.inv_proj_2w + pms.inv_proj_3w);

	// Limita la profundidad lineal a un rango válido para evitar errores (0.01 a uFar)
	linear_depth = clamp(linear_depth, 0.01, uFar);

	// Define el punto de enfoque (distancia donde la imagen está nítida)
	float focus_point = 10.0;

	// Define qué tan fuerte es el desenfoque según la diferencia de enfoque
	float focus_scale = 50.0;

	// Calcula el tamaño del desenfoque para este píxel
	float center_size = get_blur_size(linear_depth, focus_point, focus_scale);

	// Lee el color del pixel desde la textura de entrada (screen_tex)
	vec3 color = imageLoad(screen_tex, pixel).rgb;

	// Inicializa el acumulador de muestras (para promediar)
	float tot = 1.0;

	// Inicializa el radio de muestreo para el espiral
	float radius = RAD_SCALE;

	// Recorre puntos en espiral mientras el radio sea menor al desenfoque máximo
	for (float angle = 0.0; radius < MAX_BLUR_SIZE; angle += GOLDEN_ANGLE)
	{
		// Calcula una posición en espiral usando el ángulo y el radio actual
		vec2 offset = vec2(cos(angle), sin(angle)) * texel_size * radius;

		// Calcula las coordenadas UV de la muestra desplazada
		vec2 sample_uv = uv + offset;

		// Si la muestra está fuera de la imagen, sáltala
		if (sample_uv.x < 0.0 || sample_uv.x > 1.0 || sample_uv.y < 0.0 || sample_uv.y > 1.0)
			continue;

		ivec2 sample_pixel = ivec2(sample_uv * size);
		// Obtiene el color de la muestra desplazada (puedes usar imageLoad si la textura es image2D)
		vec3 sample_color = imageLoad(screen_tex, sample_pixel).rgb;

		// Obtiene la profundidad de la muestra desplazada
		float sample_depth = texture(depth_tex, sample_uv).r;

		// Convierte esa profundidad a lineal
		float sample_linear_depth = 1. / (sample_depth * pms.inv_proj_2w + pms.inv_proj_3w);
		sample_linear_depth = clamp(sample_linear_depth, 0.01, uFar);

		// Calcula el desenfoque de esa muestra
		float sample_size = get_blur_size(sample_linear_depth, focus_point, focus_scale);

		// Si la muestra está más lejos que el pixel central, limita su desenfoque
		if (sample_linear_depth > linear_depth)
			sample_size = clamp(sample_size, 0.0, center_size * 2.0);

		// AQUI QUITÉ 

		// Calcula un peso de mezcla según qué tan lejos está la muestra
		float m = smoothstep(radius - 0.5, radius + 0.5, sample_size);

		// Mezcla el color central con el de la muestra usando el peso calculado
		color += mix(color / tot, sample_color, m);
		// Aumenta el total para normalizar después
		tot += 1.0;

		// Aumenta el radio de muestreo (más lento a medida que aumenta)
		radius += RAD_SCALE / radius;
	}

	// Promedia el color final
	color /= tot;
	///////////////////
	//tone mapping
	//color = vec3(1.7, 1.8, 1.9) * color.rgb / (1.0 + color.rgb);
	//inverse gamma correction
	//color = pow(color, vec3(1.0 / DISPLAY_GAMMA));
	//////////////////

	// Escribe el color resultante en la textura de salida
	imageStore(screen_tex, pixel, vec4(color, 1.0));
}

