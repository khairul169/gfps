extends Spatial

# Exports
export (NodePath) var ScopeMesh;
export var LensEnabled = false;

# Variables
var mLensMaterial = null;

func _ready():
	# Get node
	if (typeof(ScopeMesh) == TYPE_NODE_PATH):
		ScopeMesh = get_node(ScopeMesh);
	
	# Find lens material
	if (ScopeMesh):
		for i in range(0, ScopeMesh.mesh.get_surface_count()):
			if (ScopeMesh.mesh.surface_get_name(i) != "Lens"):
				continue;
			var mat = ScopeMesh.get_surface_material(i);
			if (mat && mat is ShaderMaterial):
				mLensMaterial = mat;

func SetLensTexture(res):
	if (!LensEnabled || !mLensMaterial):
		return;
	if (!res || !res is Texture):
		res = null;
	mLensMaterial.set_shader_param("render", res);
