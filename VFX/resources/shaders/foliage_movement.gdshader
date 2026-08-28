shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform float time_scale;
uniform float wave;
instance uniform float wave_offset;
uniform float mask_black;
uniform float mask_white;
uniform sampler2D custom_texture : source_color;

void vertex() {

float time = TIME * time_scale;

float body = (VERTEX.y + 1.0) / 5.0;

float mask = smoothstep(mask_black, mask_white, 1.0 - body);

VERTEX.x += cos(time + body + wave_offset) * wave * mask;
VERTEX.z += cos(time + body + wave_offset) * wave * mask;
}

void fragment() {
    vec4 tex = texture(custom_texture, UV);
    	ALBEDO = tex.rgb;
    	ALPHA = tex.a;
}	