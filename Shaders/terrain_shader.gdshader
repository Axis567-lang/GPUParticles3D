shader_type spatial;

uniform sampler2D terrain_texture;
uniform float texture_tiling = 1.0; // Escala de repetición de la textura

uniform sampler2D heightmap;
uniform float height_scale = 5.0;
uniform vec2 terrain_size = vec2(10.0, 10.0); // Tamaño del terreno en unidades del mundo
uniform vec2 heightmap_size = vec2(1024.0, 1024.0); // Tamaño en píxeles de la textura del heightmap

void vertex() {
	// Convertir coordenadas del mesh al espacio del heightmap
	vec2 uv = (VERTEX.xz + terrain_size * 0.5) / terrain_size; // Normaliza al rango 0-1
	uv *= heightmap_size / vec2(textureSize(heightmap, 0)); // Ajustar al tamaño del heightmap

	// Obtener la altura del heightmap
	float height = texture(heightmap, uv).r;
	VERTEX.y = height * height_scale;
}

void fragment() {
	// Coordenadas UV para la textura del terreno (permitiendo tiling)
	vec2 uv = (UV * terrain_size / texture_tiling);

	// Obtener el color de la textura
	vec4 tex_color = texture(terrain_texture, uv);

	// Aplicar color al terreno
	ALBEDO = tex_color.rgb;
}
