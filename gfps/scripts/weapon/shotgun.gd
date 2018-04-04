extends "res://gfps/scripts/weapon/base_weapon.gd"

# Stats
var bullet_spread = 8;
var progressive_reload = true;

# Variables
var is_reloading = false;
var first_insert = false;

###########################################################

func _init():
	# Weapon name
	name = "base_shotgun";
	
	# Weapon stats
	clip = 8;
	ammo = 32;
	firing_mode = MODE_AUTO;
	
	recoil = Vector2(2.0, 4.5);
	firing_delay = 1.0;
	reload_time = 1.0;
	can_aim = false;

###########################################################

func think(delta):
	.think(delta);
	
	if (!is_reloading || PlayerWeapon.next_think > 0.0):
		return;
	
	if (first_insert):
		first_insert = false;
	else:
		PlayerWeapon.add_weapon_clip(1);
		PlayerWeapon.emit_signal("weapon_reload");
	
	if (PlayerWeapon.wpn_clip >= clip || PlayerWeapon.wpn_ammo <= 0):
		cancel_reload();
		return;
	
	PlayerWeapon.play_animation("reload");
	PlayerWeapon.next_think = reload_time;
	PlayerWeapon.next_idle = PlayerWeapon.next_think + 0.5;

func attach():
	.attach();
	
	is_reloading = false;

func attack():
	if (is_reloading || !.attack(false)):
		return false;
	
	# Spread bullet
	for i in range(0, bullet_spread):
		PlayerWeapon.shoot_bullet(firing_range);
	return true;

func reload():
	if (is_reloading):
		return false;
	
	# Normal reload
	if (!progressive_reload && .reload()):
		return true;
	
	if (PlayerWeapon.wpn_clip >= clip || PlayerWeapon.wpn_ammo <= 0):
		return false;
	
	is_reloading = true;
	first_insert = true;
	
	PlayerWeapon.play_animation("reload_start");
	PlayerWeapon.next_think = 0.4;
	PlayerWeapon.next_idle = PlayerWeapon.next_think + 0.1;
	return false;

func cancel_reload():
	if (!is_reloading):
		return;
	
	PlayerWeapon.play_animation("reload_end");
	PlayerWeapon.next_think = 0.4;
	is_reloading = false;

func sprint_state(sprinting):
	# Stop reload
	cancel_reload();
	PlayerWeapon.next_think = 0.0;
	PlayerWeapon.next_idle = 0.0;
	.sprint_state(sprinting);
