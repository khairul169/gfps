extends "base_weapon.gd"

# Resources
var missile_object = "";
var missile_impact = "";

# Stats
var velocity = 0.0;
var impulse = Vector3(0, 1.0, -10.0);
var explosion_range = 5.0;
var explosion_force = 4.0;

###########################################################

func _init():
	# Weapon name
	name = "base_projectile";
	
	# Weapon stats
	clip = 1;
	ammo = 100;
	firing_mode = MODE_AUTO;
	
	recoil = Vector2(1.0, 7.5);
	firing_delay = 0.2;
	reload_time = 1.0;
	
	can_aim = true;
	aim_fov = 40.0;
	aim_statsmultiplier = 0.4;

func registered():
	.registered();
	
	# Load resources
	missile_object = load_resource(missile_object);
	missile_impact = load_resource(missile_impact);
	
	# Set animation name
	animation['shoot'][1] = 'shoot';

###########################################################

func think(delta):
	if (PlayerWeapon.next_think > 0.0):
		return;
	
	if (PlayerWeapon.wpn_clip <= 0):
		animation['idle'] = 'idle_empty';
		animation['sprint'][1] = 'sprinting_e';
	else:
		animation['idle'] = 'idle';
		animation['sprint'][1] = 'sprinting';
	
	.think(delta);

func draw():
	if (PlayerWeapon.wpn_clip <= 0):
		animation['draw'] = 'draw_empty';
	else:
		animation['draw'] = 'draw';
	.draw();

func PrimaryAttack():
	if (!.PrimaryAttack(false)):
		return false;
	
	# Launch the missile
	create_projectile();
	return true;

func sprint_toggled(sprinting):
	.sprint_toggled(sprinting);
	
	if (PlayerWeapon.wpn_clip > 0):
		return;
	
	if (sprinting):
		PlayerWeapon.play_animation('pre_sprint_e');
	else:
		PlayerWeapon.play_animation('post_sprint_e');

###########################################################

func create_projectile():
	if (!missile_object || !PlayerWeapon.Controller):
		return;
	var projectile = missile_object.instance();
	if (!projectile is RigidBody):
		return;
	
	# Set missile transform
	projectile.global_transform = PlayerWeapon.get_camera_transform();
	
	# Configure missile
	projectile.add_collision_exception_with(PlayerWeapon.Controller);
	projectile.contact_monitor = true;
	projectile.contacts_reported = 1;
	projectile.connect("body_entered", self, "_projectile_colliding", [projectile]);
	
	# Add object to the world
	PlayerWeapon.add_to_world(projectile);
	
	# Set forward velocity
	if (velocity > 0.0):
		projectile.linear_velocity = -projectile.global_transform.basis.z * velocity;
		projectile.gravity_scale = 0.0;
	
	# Rigid impulse
	if (impulse.length() > 0.0):
		projectile.apply_impulse(Vector3(), projectile.global_transform.xform(impulse) - projectile.global_transform.origin);

func _projectile_colliding(body, projectile):
	if (!body || !projectile || !projectile.is_inside_tree()):
		return;
	
	if (missile_impact):
		# Create explosion particles
		var explosion = missile_impact.instance();
		PlayerWeapon.add_to_world(explosion);
		
		# Set missile transform
		explosion.global_transform.origin = projectile.global_transform.origin;
	
	# Give damage & push object in area
	for i in projectile.get_tree().get_nodes_in_group("damageable"):
		if (i.global_transform.origin.distance_to(projectile.global_transform.origin) > explosion_range):
			continue;
		if (i.has_method("give_damage")):
			i.give_damage(10.0);
	
	for i in projectile.get_tree().get_nodes_in_group("physics"):
		push_rigidbody(i, projectile.global_transform.origin);
	
	# Remove projectile from world
	projectile.queue_free();

func push_rigidbody(body, position):
	if (!body || !body.is_inside_tree() || !body is RigidBody):
		return;
	
	var dir = body.global_transform.origin - position;
	if (dir.length() > explosion_range):
		return;
	
	var impulse = dir.normalized() * clamp(1.0 - (dir.length()/explosion_range), 0.0, 1.0);
	
	# Push body!
	body.apply_impulse(Vector3(), impulse * explosion_force);
