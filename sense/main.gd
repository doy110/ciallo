extends Node2D
var viewport_size_x : int
const KILL = preload("uid://b7wuusqhxsx53")
@onready var killer: Node = $killer
var timer = Timer.new()

func _ready() -> void:
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	timer.start(3)
	viewport_size_x = get_window().size.x

func _on_timer_timeout() -> void:
	var inst: Area2D = KILL.instantiate()
	inst.position = Vector2($CharacterBody2D.global_position.x + get_viewport_rect().size.x, 130)
	killer.add_child(inst)
	timer.start(randf_range(Global.t_min,Global.t_max))

func _process(_delta: float) -> void:
	for child:Area2D in killer.get_children():
		if abs(child.global_position.x - $CharacterBody2D.global_position.x) > viewport_size_x:
			child.queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		Input.action_press("ui_accept")
		Input.action_release("ui_accept")


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://sense/main.tscn")


func _on_setting() -> void: $settings.show(); Global.paused = true
func _on_back_pressed() -> void: $settings.hide(); Global.paused = false

func _restart_with_current_settings() -> void:
	Global.speed_card = $settings/PanelContainer/CenterContainer/VBoxContainer/HBoxContainer/card.value
	Global.jump_vel = -$settings/PanelContainer/CenterContainer/VBoxContainer/HBoxContainer3/jmp.value
	Global.speed_extend = $settings/PanelContainer/CenterContainer/VBoxContainer/HBoxContainer2/ext.value
	if $settings/PanelContainer/CenterContainer/VBoxContainer/HBoxContainer4/min.value < $settings/PanelContainer/CenterContainer/VBoxContainer/HBoxContainer4/max.value:
		get_tree().change_scene_to_file("res://sense/main.tscn")
		_on_back_pressed()
	else: $settings/PanelContainer/CenterContainer/warning.show()
