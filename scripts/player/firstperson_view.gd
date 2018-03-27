extends Spatial

# Configuration
var bob_speed = 1.5;
var bob_factor = 0.008;
var bob_sprinting = 3.0;
var bob_angle = 1.0;
var sway_factor = 0.002;
var sway_limit = 0.015;
var camera_shifting = 0.02;
var on_air_factor = 0.02;
var interpolation = 8.0;

############################ DO NOT EDIT BELOW ###############################

# Nodes
var PlayerController;

# Variables
var is_bobbing = false;
var bob_cycle = 0.0;
var hvelocity = Vector3();
var view_sway = Vector3();
var custom_scale = 1.0;
var shifting_enabled = true;

func _ready():
	if (PlayerController != null):
		PlayerController.connect("camera_motion", self, "camera_motion");

func _process(delta):
	if (!PlayerController || !is_bobbing):
		return;
	
	var bob_cycleSpeed = min((hvelocity.length()/PlayerController.MoveSpeed) * bob_speed, 10.0);
	bob_cycle = fmod(bob_cycle + 360 * delta * bob_cycleSpeed, 360.0);

func _physics_process(delta):
	if (!PlayerController):
		return;
	
	# Translation vector
	var view_translation = Vector3();
	var view_rotation = Vector3();
	
	# Player horizontal movement
	hvelocity = PlayerController.linear_velocity;
	hvelocity.y = 0.0;
	
	if (hvelocity.length() >= 1.0 && !PlayerController.is_climbing):
		is_bobbing = true;
	else:
		if (bob_cycle > 0.0):
			bob_cycle = 0.0;
		is_bobbing = false;
	
	var factor = bob_factor * custom_scale;
	
	if (PlayerController.is_sprinting):
		factor *= bob_sprinting;
	
	# Shift weapon position
	if (shifting_enabled):
		view_translation.y += sin(deg2rad(-PlayerController.camera_rotation.x)) * camera_shifting;
	
	# Weapon y-pos when jumping
	if (shifting_enabled && !PlayerController.is_climbing):
		if (PlayerController.linear_velocity.y > 0.5):
			view_translation.y += on_air_factor;
		
		if (PlayerController.linear_velocity.y < -0.5):
			view_translation.y -= on_air_factor;
	
	if (is_bobbing):
		if (!PlayerController.is_sprinting):
			view_translation.y -= factor;
			view_translation.z += factor * 1.4;
		
		view_translation.x += sin(deg2rad(bob_cycle)) * factor;
		view_translation.y += abs(cos(deg2rad(bob_cycle))) * factor - factor;
		
		view_rotation.y += cos(deg2rad(bob_cycle)) * bob_angle;
		view_rotation.z += sin(deg2rad(bob_cycle)) * -bob_angle;
	
	if (view_sway.length() > 0.0):
		view_translation += view_sway * custom_scale;
		view_sway = view_sway.linear_interpolate(Vector3(), interpolation * delta);
	
	translation = translation.linear_interpolate(view_translation, interpolation * delta);
	rotation_degrees = rotation_degrees.linear_interpolate(view_rotation, interpolation * delta);

func camera_motion(rel):
	view_sway.x = clamp(view_sway.x - rel.x * sway_factor, -sway_limit, sway_limit);
	view_sway.y = clamp(view_sway.y + rel.y * sway_factor, -sway_limit, sway_limit);

func set_custom_scale(scale):
	custom_scale = scale;

func set_shifting_enabled(enabled):
	shifting_enabled = enabled;
