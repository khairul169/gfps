extends Node

# Properties
export (NodePath) var player_weapon;
export var slot_count = 6;

# Variables
var weapon_slot = [];
var active_slot = -1;

func _ready():
	# Get player weapon
	if (player_weapon && typeof(player_weapon) == TYPE_NODE_PATH):
		player_weapon = get_node(player_weapon);
	
	# Resize weapon slot
	weapon_slot.resize(slot_count);

func _input(event):
	if (!player_weapon || weapon_slot.size() <= 0):
		return;
	
	if (event is InputEventKey && event.is_pressed() && event.scancode >= KEY_1 && event.scancode < KEY_1 + slot_count):
		select_item(event.scancode - KEY_1);
	
	if (event is InputEventMouseButton && event.is_pressed()):
		if (event.button_index == BUTTON_WHEEL_UP):
			scroll_weapon(-1);
		if (event.button_index == BUTTON_WHEEL_DOWN):
			scroll_weapon(1);

"""
func drop_weapon(slot):
	if (!player_weapon || weapon_slot.size() <= 0 || slot < 0 || slot >= weapon_slot.size()):
		return;
	
	if (player_weapon.has_method("drop_weapon")):
		player_weapon.drop_weapon(weapon_slot[slot]['id'], player_weapon.wpn_clip, player_weapon.wpn_ammo);
	
	active_slot = -1;
"""

func set_item(slot, wpnid, auto_switch = true, drop_item = false):
	if (!player_weapon || weapon_slot.size() <= 0 || slot < 0 || slot >= weapon_slot.size()):
		return;
	
	var weapon = player_weapon.get_weapon_by_id(wpnid);
	if (!weapon):
		return;
	
	#if (active_slot >= 0):
	#	drop_weapon(active_slot);
	
	# Set slot item
	weapon_slot[slot] = { 'id' : wpnid, 'clip' : weapon.clip, 'ammo' : weapon.ammo };
	
	# Switch weapon
	if (auto_switch):
		select_item(slot);

func select_item(slot):
	if (!player_weapon || weapon_slot.size() <= 0 || slot == active_slot || slot < 0 || slot >= weapon_slot.size()):
		return;
	if (!weapon_slot[slot] || weapon_slot[slot]['id'] < 0):
		return;
	
	# Store current clip & ammo to inventory slot
	var curwpn = player_weapon.get_current_weapon();
	if (curwpn && active_slot >= 0):
		set_item_ammo(active_slot, player_weapon.wpn_clip, player_weapon.wpn_ammo);
	
	# Set current weapon
	player_weapon.set_current_weapon(weapon_slot[slot]['id']);
	player_weapon.set_weapon_ammo(weapon_slot[slot]['clip'], weapon_slot[slot]['ammo']);
	
	# Set active slot
	active_slot = slot;

func remove_item(slot, switch_other = false):
	if (!player_weapon || weapon_slot.size() <= 0  || slot < 0 || slot >= weapon_slot.size()):
		return;
	if (!weapon_slot[slot] || weapon_slot[slot]['id'] < 0):
		return;
	
	# Reset view scene
	if (active_slot == slot):
		player_weapon.set_current_weapon(null);
	
	# Remove item from inventory
	weapon_slot[slot] = null;
	
	# Select other weapon
	if (switch_other):
		for i in range(0, weapon_slot.size()):
			if (weapon_slot[i] && weapon_slot[i]['id'] > 0):
				select_item(i);
				break;

func scroll_weapon(dir):
	var cur_slot = active_slot + dir;
	var try = 0;
	
	# Check if item is exist
	while (try < slot_count && (!weapon_slot[cur_slot] || weapon_slot[cur_slot]['id'] < 0)):
		cur_slot += dir;
		try += 1;
		
		if (cur_slot < 0):
			cur_slot = slot_count + cur_slot;
		if (cur_slot >= slot_count):
			cur_slot = 0;
	
	# Switch weapon
	if (cur_slot != active_slot):
		select_item(cur_slot);

func set_item_ammo(slot, clip, ammo):
	if (!player_weapon || weapon_slot.size() <= 0 || slot < 0 || slot >= weapon_slot.size()):
		return;
	if (!weapon_slot[slot] || weapon_slot[slot]['id'] < 0):
		return;
	
	weapon_slot[slot]['clip'] = clip;
	weapon_slot[slot]['ammo'] = ammo;

func set_slot_count(count):
	# Resize slot size
	slot_count = count;
	weapon_slot.resize(count);
