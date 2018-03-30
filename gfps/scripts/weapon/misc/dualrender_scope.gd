extends Spatial

# Exports
export (NodePath) var ScopeMesh;
export var LensMaterialId = 0;

# Variables
var lens_material = null;

func _ready():
	# Get node
	if (typeof(ScopeMesh) == TYPE_NODE_PATH):
		ScopeMesh = get_node(ScopeMesh);
	
	# No mesh selected
	if (!ScopeMesh):
		return;
	
	# Find lens material
	if (LensMaterialId < 0 || LensMaterialId >= ScopeMesh.mesh.get_surface_count()):
		return;
	
	# Get lens shader material
	var mat = ScopeMesh.get_surface_material(LensMaterialId);
	if (mat && mat is ShaderMaterial):
		lens_material = mat;

func set_lens_texture(res):
	if (!lens_material):
		return;
	if (!res || !res is Texture):
		res = null;
	
	lens_material.set_shader_param("enable_render", res != null);
	lens_material.set_shader_param("render", res);
