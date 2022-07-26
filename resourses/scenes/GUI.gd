extends ReferenceRect

onready var air_mode_button: TextureButton = $ModeSetButtons/Air
onready var build_mode_button: TextureButton = $ModeSetButtons/Build
onready var hp_bar: TextureProgress = $HPBarContainer/HPBar
onready var score_label: Label = $PanelContainer2/ScoreContainer/Score
onready var timeout_label: Label = $PanelContainer/Timeout

onready var controls_build_tooltip: Control = $ControlsTooltip/BuildTooltip
onready var controls_fire_tooltip: Control = $ControlsTooltip/FireTooltip
onready var controls_tooltip: Control = $ControlsTooltip

var last_settings: Dictionary
var player_respawn_time: int = 0

func _ready():
	if PlayerState.connect("player_selection_state_changed", self, "_mode_selected") != OK:
		get_tree().quit(1)
	if PlayerState.connect("player_hp_changed_sig", self, "_player_hp_changed") != OK:
		get_tree().quit(2)
	if PlayerState.connect("player_score_changed_sig", self, "_player_score_changed") != OK:
		get_tree().quit(3)
	if Settings.connect("settings_changed", self, "settings_changed"):
		get_tree().quit(4)


func _player_hp_changed(new_hp):
	hp_bar.value = new_hp


func _player_score_changed(new_score):
	score_label.text = String(new_score)


func world_end_time_changed(new_time: int):
	timeout_label.text = String(int(new_time / 60)) + ":"
	if int(new_time % 60) < 10:
		timeout_label.text += "0"
	timeout_label.text += String(int(new_time % 60))


func settings_changed(settings):
	last_settings = settings
	set_control_tooltip_state()


func _mode_selected(mode: int):
	set_control_tooltip_state()
	air_mode_button.pressed = false
	build_mode_button.pressed = false
	match mode:
		PlayerState.PLAYER_FIRING_BULLETS:
			air_mode_button.pressed = true
		PlayerState.PLAYER_BUILDING:
			build_mode_button.pressed = true


func set_control_tooltip_state():
	controls_tooltip.visible = last_settings.control_tips
	controls_fire_tooltip.visible = false
	controls_build_tooltip.visible = false
	if PlayerState.player_mode == PlayerState.PLAYER_FIRING_BULLETS:
		controls_fire_tooltip.visible = true
	if PlayerState.player_mode == PlayerState.PLAYER_BUILDING:
		controls_build_tooltip.visible = true


func player_respawning(time: int):
	if time > 0:
		$RespawnPanel.visible = true
		$RespawnPanel/Label.text = String(time)
		yield(get_tree().create_timer(1), "timeout")
		player_respawning(time - 1)
	else:
		$RespawnPanel.visible = false


func insufficient_funds():
	$AnimationPlayer.play("not_enough_funds")		


func _on_Build_button_up():
	PlayerState._player_changed_mode(PlayerState.PLAYER_BUILDING)


func _on_Air_button_up():
	PlayerState._player_changed_mode(PlayerState.PLAYER_FIRING_BULLETS)
