shader_type spatial;

uniform sampler2D heightmap; // Imagen en escala de grises
uniform float height_scale = 5.0; // Escala de altura

void vertex() {
	vec2 uv = (VERTEX.xz + vec2(5.0)) / 10.0; // Normalizar UVs al tamaño del terreno
	float height = texture(heightmap, uv).r; // Obtener altura del heightmap
	VERTEX.y = height * height_scale; // Modificar vértice según el mapa de alturas
}
