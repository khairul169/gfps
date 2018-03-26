extends Spatial

# Exports
export (NodePath) var ScopeMesh;
export var LensEnabled = false;

# Variables
var lens_material = null;

func _ready():
	# Get node
	if (typeof(ScopeMesh) == TYPE_NODE_PATH):
		ScopeMesh = get_node(ScopeMesh);
	
	if (!ScopeMesh):
		return;
	
	# Find lens material
	for i in range(0, ScopeMesh.mesh.get_surface_count()):
		if (ScopeMesh.mesh.surface_get_name(i) != "lens"):
			continue;
		var mat = ScopeMesh.get_surface_material(i);
		if (mat && mat is ShaderMaterial):
			lens_material = mat;

func set_lens_texture(res):
	if (!LensEnabled || !lens_material):
		return;
	if (!res || !res is Texture):
		res = null;
	lens_material.set_shader_param("render", res);
