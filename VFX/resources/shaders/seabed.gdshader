shader_type spatial;

uniform sampler2D top_texture : source_color, filter_nearest_mipmap;
uniform sampler2D side_texture : source_color, filter_nearest_mipmap;

uniform float top_scale = 1.0;
uniform float side_scale = 1.0;

uniform float blend_start = 0.35;
uniform float blend_end = 0.75;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
    vec3 n = abs(world_normal);

    vec2 top_uv = world_position.xz / top_scale;
    vec3 top_color = texture(top_texture, top_uv).rgb;

    vec2 side_uv_x = world_position.yz / side_scale;
    vec2 side_uv_z = world_position.xy / side_scale;

    vec3 side_x = texture(side_texture, side_uv_x).rgb;
    vec3 side_z = texture(side_texture, side_uv_z).rgb;

    float side_weight = n.x + n.z;

    vec3 side_color =
        (side_x * n.x + side_z * n.z)
        / max(side_weight, 0.001);

    // -------------------------
    // Blend góra <-> bok
    // -------------------------
    float top_factor = smoothstep(
        blend_start,
        blend_end,
        n.y
    );

    ALBEDO = mix(
        side_color,
        top_color,
        top_factor
    );
}