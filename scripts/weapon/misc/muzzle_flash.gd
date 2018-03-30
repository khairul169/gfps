extends Spatial

# Nodes
onready var mesh = get_node("Mesh");
onready var anim = get_node("AnimationPlayer");

func _ready():
	# Hide all object
	$Mesh.hide();
	$Particles.emitting = false;
	$Light.hide();

func flash():
	if (!is_inside_tree()):
		return;
	
	# Show muzzleflash
	mesh.rotation_degrees.z = rand_range(0, 360.0);
	anim.play("flash");
