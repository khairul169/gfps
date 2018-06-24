shader_type spatial;

uniform bool enable_render = false;
uniform sampler2D render : hint_black;
uniform sampler2D overlay : hint_black;

void fragment() {
	vec4 tex = texture(render, UV).rgba;
	vec4 ovl = texture(overlay, UV).rgba;
	
	if (enable_render) {
		if ((tex.r + tex.g + tex.b)/3.0 <= 0.0) {
			ALPHA = ovl.a;
		}
		
		ALBEDO = mix(tex.rgb, ovl.rgb, ovl.a);
		METALLIC = 0.0;
		ROUGHNESS = 1.0;
	
	} else {
		ALBEDO = mix(vec3(0.2), ovl.rgb, ovl.a);
		METALLIC = 1.0;
		ROUGHNESS = 0.2;
	}
}