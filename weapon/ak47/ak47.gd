extends "res://gfps/scripts/weapon/base_weapon.gd"

func _init():
	# Weapon name
	name = "AK47";
	
	# Resources
	view_scene = "view.tscn";
	
	# Sounds
	sfx['shoot'] = "ak47-shoot.wav";
	
	# Weapon stats
	clip = 30;
	ammo = 90;
	
	reload_time = 2.4;
	muzzle_size = 1.0;
	recoil = Vector2(1.8, 2.8);
	spread = Vector2(2.8, 8.0);
	move_speed = 0.94;
	
	firing_mode = MODE_AUTO;
	firing_delay = 1.0/10.0;
	firing_range = 100.0;
	
	can_aim = true;
	aim_fov = 50.0;
	aim_statsmultiplier = 0.56;
	aim_hidecrosshair = false;
