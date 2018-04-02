extends Spatial

# Nodes
onready var mesh = get_node("mesh");
onready var anim = get_node("AnimationPlayer");

func _ready():
	# Hide all object
	$mesh.hide();
	$particles.emitting = false;
	$light.hide();

func flash():
	if (!is_inside_tree()):
		return;
	
	# Show muzzleflash
	mesh.rotation_degrees.z = rand_range(0, 360.0);
	anim.play("flash");

func set_size(size):
	var scale = Vector3(1,1,1) * size;
	$mesh.scale = scale
	$light.scale = scale;
