extends Spatial

# Nodes
onready var controller = get_node("controller");
onready var weapon = get_node("weapon");

# Weapons
# var weapon_handgun;

func _ready():
	# Set network player node
	if (has_node("/root/network_mgr")):
		get_node("/root/network_mgr").player_node = self;
		get_node("/root/network_mgr").connect("server_hosted", self, "on_server_hosted");
	
	# Load weapon list
	# weapon_handgun = weapon.register_weapon("res://Scripts/Weapon/Handgun.gd");
	
	# Connect weapon signals
	weapon.connect("weapon_attach", self, "update_hud");
	weapon.connect("weapon_attack1", self, "update_hud");
	weapon.connect("weapon_attack2", self, "update_hud");
	weapon.connect("weapon_unload", self, "update_hud");
	weapon.connect("weapon_reload", self, "update_hud");
	
	# Enable character sprinting
	controller.enable_sprint = true;
	
	# Set primary weapon
	# weapon.set_current_weapon(weapon_handgun);
	
	# Change camera y-rotation to follow this node rotation
	controller.set_camera_rotation(0.0, rotation_degrees.y);

func _input(event):
	if (event is InputEventKey && event.pressed):
		# Reload weapon
		if (event.scancode == KEY_R):
			weapon.wpn_reload();
		
		# Toggle dual render scope
		if (event.scancode == KEY_L):
			weapon.EnableScopeRender = !weapon.EnableScopeRender;
	
	if (event is InputEventMouseButton):
		if (weapon && event.button_index == BUTTON_LEFT):
			weapon.input['attack1'] = event.pressed;
		
		if (weapon && event.button_index == BUTTON_RIGHT):
			weapon.input['attack2'] = event.pressed;

func _physics_process(delta):
	# Update player input
	if (controller):
		controller.input['forward'] = Input.is_key_pressed(KEY_W);
		controller.input['backward'] = Input.is_key_pressed(KEY_S);
		controller.input['left'] = Input.is_key_pressed(KEY_A);
		controller.input['right'] = Input.is_key_pressed(KEY_D);
		
		controller.input['jump'] = Input.is_key_pressed(KEY_SPACE);
		controller.input['walk'] = Input.is_key_pressed(KEY_ALT);
		controller.input['sprint'] = Input.is_key_pressed(KEY_SHIFT);

func update_hud():
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

func on_server_hosted():
	if (has_node("/root/network_mgr")):
		get_node("/root/network_mgr").create_local_player();
