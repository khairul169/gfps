extends "res://gfps/scripts/player/controller.gd"

# Nodes
onready var weapon = get_node("weapon");

# Weapons
var weapon_ak47;
var weapon_g36c;

func _ready():
	# Load weapon configuration
	load_weapon();
	
	# Enable character sprinting
	enable_sprint = true;

func _input(event):
	if (event is InputEventKey && event.pressed):
		# Reload weapon
		if (weapon && event.scancode == KEY_R):
			weapon.wpn_reload();
		
		# Toggle dual render scope
		if (weapon && event.scancode == KEY_L):
			weapon.EnableScopeRender = !weapon.EnableScopeRender;
	
	if (event is InputEventMouseButton):
		if (weapon && event.button_index == BUTTON_LEFT):
			weapon.input['attack'] = event.pressed;
		
		if (weapon && event.button_index == BUTTON_RIGHT):
			weapon.input['special'] = event.pressed;

func _physics_process(delta):
	# Update player input
	input['forward'] = Input.is_key_pressed(KEY_W);
	input['backward'] = Input.is_key_pressed(KEY_S);
	input['left'] = Input.is_key_pressed(KEY_A);
	input['right'] = Input.is_key_pressed(KEY_D);
	
	input['jump'] = Input.is_key_pressed(KEY_SPACE);
	input['walk'] = Input.is_key_pressed(KEY_ALT);
	input['sprint'] = Input.is_key_pressed(KEY_SHIFT);
	
	# Update crosshair size
	if (weapon):
		$interface/crosshair.spread = weapon.wpn_spread;

func load_weapon():
	if (!weapon):
		return;
	
	# Connect weapon signals
	weapon.connect("weapon_attach", self, "update_hud");
	weapon.connect("weapon_attack", self, "update_hud");
	weapon.connect("weapon_special", self, "update_hud");
	weapon.connect("weapon_unload", self, "update_hud");
	weapon.connect("weapon_reload", self, "update_hud");
	
	# Weapon shoot effect for crosshair
	weapon.connect("weapon_attack", $interface/crosshair, "shoot");
	
	# Register weapon
	weapon_ak47 = weapon.register_weapon("res://weapon/ak47/ak47.gd");
	weapon_g36c = weapon.register_weapon("res://weapon/g36c/g36c.gd");
	
	# Set primary weapon
	weapon.set_current_weapon(weapon_g36c);

func update_hud():
	if (!weapon):
		return;
	
	var cur_wpn = weapon.get_current_weapon();
	if (cur_wpn != null):
		# Set ammo label text
		$interface/ammo.show();
		$interface/ammo.text = str(weapon.wpn_clip).pad_zeros(2) + "/" + str(weapon.wpn_ammo).pad_zeros(3);
		
		# Weapon name
		$interface/weapon_name.show();
		$interface/weapon_name.text = cur_wpn.name;
	
	else:
		# Hide HUD
		$interface/ammo.hide();
		$interface/weapon_name.hide();
	
	if (cur_wpn && (!cur_wpn.is_aiming || !cur_wpn.aim_hidecrosshair)):
		$interface/crosshair.visible = true;
	else:
		$interface/crosshair.visible = false;