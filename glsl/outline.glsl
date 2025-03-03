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

void main()
{
    ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);
    vec2 size = pms.screen_size;
    // calculate uv
    vec2 uv = pixel / size;

    if(pixel.x >= size.x || pixel.y >= size.y) return;

    float depth = texture(depth_tex, uv).r;
    float linear_depth = 1. / (depth * pms.inv_proj_2w + pms.inv_proj_3w);
    linear_depth = clamp(linear_depth / 50., 0., 1.);

    vec4 color = imageLoad(screen_tex, pixel);

    // Border Outline
    float depth_border = 1.;
	
	for (float x = -sample_size; x <= sample_size; x++) {
		for (float y = -sample_size; y <= sample_size; y++) {
			if (length(vec2(x, y)) > sample_size)
				continue;
            
			vec2 offset_uv = uv + vec2(x, y) / size + offset;
            float offset_depth = texture(depth_tex, offset_uv).r;

            float offset_linear_depth = 1. / (offset_depth * pms.inv_proj_2w + pms.inv_proj_3w);
            offset_linear_depth = clamp(offset_linear_depth / 30., 0., 1.);
            
			if (abs(linear_depth - offset_linear_depth) > 0.4) {
				depth_border = 0.0;
				break;
			}
		}
		if (depth_border == 0.0)
			break;
	}
    
    imageStore(screen_tex, pixel, vec4(color.rgb * depth_border, 1.0));

}

/*
const vec2 offset = vec2(0.0001);
const float sample_size = 5.0;

float get_linear_depth(vec2 uv) {
	float raw_depth = texture(depth_texture, uv).r;
	vec3 ndc = vec3(uv * 2.0 - 1.0, raw_depth);
	vec4 view = params.inv_proj_mat * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

void main() {
	vec2 size = params.raster_size;
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	vec2 uv_normalized = uv / size;
	
	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}
	
	vec4 color = imageLoad(color_image, uv);
	float depth = get_linear_depth(uv_normalized + offset);
	float depth_border = 1.0;
	
	for (float x = -sample_size; x <= sample_size; x++) {
		for (float y = -sample_size; y <= sample_size; y++) {
			if (length(vec2(x, y)) > sample_size)
				continue;

			float offset_depth = get_linear_depth(uv_normalized + vec2(x, y) / size + offset);
            
			if (abs(depth - offset_depth) > 1.0) {
				depth_border = 0.0;
				break;
			}
		}
		if (depth_border == 0.0)
			break;
	}
	
	imageStore(color_image, uv, vec4(color.rgb * depth_border, 1.0));
}
*/
