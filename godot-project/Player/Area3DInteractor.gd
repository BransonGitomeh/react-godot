extends Area3D

@export var generator : Resource
@export var inventory_menu := NodePath()
@export var ground_items := NodePath()

func _ready():
	# Hide the inventory menu when the area is ready
	get_node(inventory_menu).hide()

# Handle input events
func _unhandled_input(event):
	if event.is_action_pressed("menu_inventory"):
		toggle_inventory_menu()

# Toggle the visibility of the inventory menu
func toggle_inventory_menu():
	var menu_node = get_node(inventory_menu)
	menu_node.visible = !menu_node.visible

# Respond when the generator is pressed
func _on_Generator_pressed():
	var item_manager = get_node(ground_items)
	for x in generator.get_items():
		item_manager.add_item(x, global_position + Vector3(0, 0.5, 0))

# Handle item pickup when entering the area
func _on_ItemPickup_body_entered(body : Node):
	if body.is_in_group("ground_item") && !body.filter_hidden:
		body.try_pickup(get_node(inventory_menu).main_inventory)

# Handle inventory button press
func _on_inworld_inv_button_pressed(inventory_view, inventory_name):
	get_node(inventory_menu).open_inworld_inventory(inventory_view, inventory_name)

# Handle item clicks
func _on_items_item_clicked(item_node : Node):
	_on_ItemPickup_body_entered(item_node)


func _on_body_entered(body):
	if body.is_in_group("ground_item") && !body.filter_hidden:
		body.try_pickup(get_node(inventory_menu).main_inventory)
