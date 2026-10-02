extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		Global.player_died.emit()
