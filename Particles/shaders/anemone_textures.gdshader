shader_type canvas_item;

uniform sampler2D texture_a;
uniform sampler2D texture_b;
uniform float blend : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 a = texture(texture_a, UV);
    vec4 b = texture(texture_b, UV);

    COLOR = mix(a, b, blend);
}
