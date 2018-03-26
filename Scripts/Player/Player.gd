extends Spatial

# Nodes
onready var controller = get_node("Controller");
onready var weapon = get_node("Weapon");

# Weapons
# var weapon_handgun;

func _ready():
	# Set network player node
	if (has_node("/root/network_mgr")):
		get_node("/root/network_mgr").mPlayerNode = self;
		get_node("/root/network_mgr").connect("server_hosted", self, "on_server_hosted");
	
	# Load weapon list
	# weapon_handgun = weapon.RegisterWeapon("res://Scripts/Weapon/Handgun.gd");
	
	# Connect weapon signals
	weapon.connect("weapon_attach", self, "update_hud");
	weapon.connect("weapon_attack1", self, "update_hud");
	weapon.connect("weapon_attack2", self, "update_hud");
	weapon.connect("weapon_unload", self, "update_hud");
	weapon.connect("weapon_reload", self, "update_hud");
	
	# Enable character sprinting
	controller.mCanSprinting = true;
	
	# Set primary weapon
	# weapon.SetActiveWeapon(weapon_handgun);
	
	# Change camera y-rotation to follow this node rotation
	controller.SetCameraRotation(0.0, rotation_degrees.y);

func _input(event):
	if (event is InputEventKey && event.pressed):
		# Reload weapon
		if (event.scancode == KEY_R):
			weapon.Reload();
		
		# Toggle dual render scope
		if (event.scancode == KEY_L):
			weapon.EnableScopeRender = !weapon.EnableScopeRender;
	
	if (event is InputEventMouseButton):
		if (weapon && event.button_index == BUTTON_LEFT):
			weapon.mInput['attack1'] = event.pressed;
		
		if (weapon && event.button_index == BUTTON_RIGHT):
			weapon.mInput['attack2'] = event.pressed;

func _physics_process(delta):
	# Update player input
	if (controller):
		controller.mInput['forward'] = Input.is_key_pressed(KEY_W);
		controller.mInput['backward'] = Input.is_key_pressed(KEY_S);
		controller.mInput['left'] = Input.is_key_pressed(KEY_A);
		controller.mInput['right'] = Input.is_key_pressed(KEY_D);
		
		controller.mInput['jump'] = Input.is_key_pressed(KEY_SPACE);
		controller.mInput['walk'] = Input.is_key_pressed(KEY_ALT);
		controller.mInput['sprint'] = Input.is_key_pressed(KEY_SHIFT);

func update_hud():
	var cur_wpn = weapon.GetCurrentWeapon();
	if (cur_wpn != null):
		# Set ammo label text
		$HUD/Ammo.show();
		$HUD/Ammo.text = str(weapon.mClip).pad_zeros(2) + "/" + str(weapon.mAmmo).pad_zeros(3);
		
		# Weapon name
		$HUD/WeaponName.show();
		$HUD/WeaponName.text = cur_wpn.mName;
	
	else:
		# Hide HUD
		$HUD/Ammo.hide();
		$HUD/WeaponName.hide();

func on_server_hosted():
	if (has_node("/root/network_mgr")):
		get_node("/root/network_mgr").CreateLocalPlayer();
