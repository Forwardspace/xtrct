shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE:hint_screen_texture,filter_linear_mipmap;

uniform vec2 player_pos;

uniform vec2 map_position_global;
uniform vec2 camera_zoom;
uniform vec2 viewport_size;

uniform float distance_threshold : hint_range(1.0, 400.0) = 50.0;
uniform float transition_threshold: hint_range(1.0, 100.0) = 50.0;
uniform vec4 hidden_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 world_pos = (SCREEN_UV) * viewport_size - map_position_global;
	world_pos /= max(camera_zoom, 0.01);

	float dist = distance(world_pos, player_pos);

	if (dist < distance_threshold) {
		if (distance_threshold - dist < transition_threshold) {
			COLOR = mix(hidden_color, texture(SCREEN_TEXTURE, SCREEN_UV), (distance_threshold - dist) / max(transition_threshold, 1.0));
		}
		else {
			COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
		}
	}
	else {
		COLOR = hidden_color;
	}
}