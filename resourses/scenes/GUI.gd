extends ReferenceRect

onready var air_mode_button: TextureButton = $ModeSetButtons/Air
onready var build_mode_button: TextureButton = $ModeSetButtons/Build
onready var hp_bar: TextureProgress = $HPBarContainer/HPBar
onready var score_label: Label = $PanelContainer2/ScoreContainer/Score
onready var timeout_label: Label = $PanelContainer/Timeout

func _ready():
	if PlayerState.connect("player_selection_state_changed", self, "_mode_selected") != OK:
		get_tree().quit(1)
	if PlayerState.connect("player_hp_changed_sig", self, "_player_hp_changed") != OK:
		get_tree().quit(2)
	if PlayerState.connect("player_score_changed_sig", self, "_player_score_changed") != OK:
		get_tree().quit(3)


func _player_hp_changed(new_hp):
	hp_bar.value = new_hp


func _player_score_changed(new_score):
	score_label.text = String(new_score)


func world_end_time_changed(new_time: int):
	timeout_label.text = String(int(new_time / 60)) + ":"
	if int(new_time % 60) < 10:
		timeout_label.text += "0"
	timeout_label.text += String(int(new_time % 60))


func _mode_selected(mode: int):
	air_mode_button.pressed = false
	build_mode_button.pressed = false
	match mode:
		PlayerState.PLAYER_FIRING_BULLETS:
			air_mode_button.pressed = true
		PlayerState.PLAYER_BUILDING:
			build_mode_button.pressed = true


func _on_Build_button_down():
	_mode_selected(PlayerState.PLAYER_BUILDING)


func _on_Air_button_down():
	_mode_selected(PlayerState.PLAYER_FIRING_BULLETS)


func _on_Build_button_up():
	_mode_selected(PlayerState.PLAYER_BUILDING)


func _on_Air_button_up():
	_mode_selected(PlayerState.PLAYER_FIRING_BULLETS)
