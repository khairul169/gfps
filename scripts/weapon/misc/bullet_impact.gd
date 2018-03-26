extends Spatial

# Variables
var timeout = 0.0;
var spawn_bullethole = true;

func _ready():
	# Emit particles
	$ParticleFire.emitting = true;
	$ParticleDust.emitting = true;
	
	# Set timeout
	timeout = rand_range(5.0, 8.0);
	
	if (!timeout):
		$Mesh.hide();

func _process(delta):
	if (timeout > 0.0):
		timeout -= delta;
		return;
	
	# Remove node
	queue_free();
