shader_type spatial;
uniform float time_scale;
uniform float side_to_side;
uniform float pivot;
uniform float wave;
uniform float vertical_wave;
uniform float vertical_bend;
instance uniform float vertical_bend_offset;
uniform float twist;
uniform float mask_black;
uniform float mask_white;
uniform sampler2D custom_texture : source_color;
uniform bool use_vertex_color_as_albedo = true;

void vertex() {

float time = TIME * time_scale;

VERTEX.x += cos(time) * side_to_side;

float pivot_angle = cos(time) * 0.1 * pivot;
mat2 rotation_matrix = mat2(vec2(cos(pivot_angle), -sin(pivot_angle)), vec2(sin(pivot_angle), cos(pivot_angle)));

VERTEX.xz = rotation_matrix * VERTEX.xz;

float body = (VERTEX.z + 0.68) / 1.36;
VERTEX.x += cos(time + body * 6.0) * wave * (1.0 - body);

VERTEX.y += cos(time) * vertical_wave;
float vertical_curve = sin(
    time + body * 0.5 + vertical_bend_offset
) * vertical_bend * (10.0 - body);

VERTEX.y += vertical_curve;

float twist_angle = cos(time + body) * 0.3 * twist;
mat2 twist_matrix = mat2(vec2(cos(twist_angle), -sin(twist_angle)), vec2(sin(twist_angle), cos(twist_angle)));

VERTEX.xy = twist_matrix * VERTEX.xy;

float mask = smoothstep(mask_black, mask_white, 1.0 - body);
VERTEX.x += cos(time + body) * mask * wave;
VERTEX.xy = mix(VERTEX.xy, twist_matrix * VERTEX.xy, mask);


}

void fragment() {
    ALBEDO = texture(custom_texture, UV).rgb;
    //ALPHA = COLOR.a;
}
