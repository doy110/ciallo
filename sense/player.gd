extends CharacterBody2D

var speed_card = Global.speed_card
var jump_vel = Global.jump_vel
var speed_extend  = Global.speed_extend
@onready var hi: Label = $"../UI/VBoxContainer/HBoxContainer/hi"
@onready var score: Label = $"../UI/VBoxContainer/HBoxContainer2/score"
var saver = ConfigFile.new()
var hi_score : int = 0
var is_new_record = false
var streams = ["res://assets/voice/meg008_001.ogg", "res://assets/voice/meg103_001.ogg", "res://assets/voice/meg104_001.ogg", "res://assets/voice/meg202_002.ogg", "res://assets/voice/meg203_002.ogg", "res://assets/voice/meg203_082.ogg", "res://assets/voice/meg203_105.ogg", "res://assets/voice/meg205_001.ogg", "res://assets/voice/meg206_002.ogg", "res://assets/voice/meg209_005.ogg", "res://assets/voice/meg215_001.ogg", "res://assets/voice/meg215_038.ogg", "res://assets/voice/meg_sys_01.ogg"]
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	if Global.paused: Global.paused = false
	if saver.load("user://savedata") == OK:
		hi_score = saver.get_value("game","score")
	else: saver.set_value("game","score",0); saver.save("user://savedata")
	hi.text = "%010d" % hi_score
	Global.player_died.connect(_on_player_died)
	get_tree().set_debug_collisions_hint(true)

func _physics_process(delta: float) -> void:
	if not Global.paused:
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			audio_stream_player_2d.stream = load(streams[randi_range(0,len(streams) - 1)])
			audio_stream_player_2d.play()
			velocity.y = jump_vel

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		if speed_extend < 24.0:
			speed_extend += 0.01 * delta
			velocity.x = (6.0 + speed_extend) * speed_card
		
		score.text = "%010d" % round(global_position.x * 0.025)
		if round(global_position.x * 0.025) > hi_score:
			if is_new_record == false:
				if hi_score != 0:
					pass # Play sound here.
				is_new_record = true
			hi.text = score.text
		move_and_slide()
	
func _on_player_died() -> void:
	Global.paused = true
	audio_stream_player_2d.stream = load("res://assets/voice/meg008_001.ogg")
	if round(global_position.x * 0.025) > hi_score:
		saver.set_value("game","score",round(global_position.x * 0.025))
	$AnimationPlayer.play("zoom")
	await $AnimationPlayer.animation_finished
	$AnimationPlayer.play("rot")
	saver.save("user://savedata")
	$"../Retry".show()
	$"../Retry/PanelContainer/CenterContainer/VBoxContainer/score".text = "分数:{0}\n最高:{1}".format([round(global_position.x * 0.025), round(global_position.x * 0.025) if round(global_position.x * 0.025) > hi_score else hi_score])
	$"../Retry/PanelContainer/CenterContainer/VBoxContainer/prop".text = "基础速度：{0}\n跳跃高度：{1}\n初始难度：{2}\n当前难度：{3}".format([Global.speed_card, -Global.jump_vel, Global.speed_extend, speed_extend])
