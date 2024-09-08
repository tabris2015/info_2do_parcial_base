shader_type canvas_item;

//uniform float darkness : hint_range(0.0, 1.0) = 0.0; // Controls the darkness
uniform vec4 color_modulate = vec4(1.0, 1.0, 1.0, 1.0); // Modulate color

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    tex_color.rgb *= color_modulate.rgb;
    //tex_color.rgb *= (1.0 - darkness);
    tex_color.a *= color_modulate.a;
    COLOR = tex_color;
}
