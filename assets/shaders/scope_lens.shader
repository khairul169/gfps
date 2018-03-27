shader_type spatial;
render_mode unshaded;

uniform sampler2D render : hint_black;
uniform sampler2D overlay : hint_black;

void fragment() {
	vec4 tex = texture(render, UV).rgba;
	vec4 ovl = texture(overlay, UV).rgba;
	
	if ((tex.r + tex.g + tex.b)/3.0 <= 0.0) {
		ALPHA = ovl.a;
	}
	
	tex.rgb = mix(tex.rgb, ovl.rgb, ovl.a);
	
	ALBEDO = tex.rgb;
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
}