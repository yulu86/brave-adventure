# 主角动画选择单元测试（M3/M4）。
#
# 覆盖 player.gd 的 pick_animation 纯函数（空中选 jump / 移动选 run / 静止选 idle）。
# 遵从宪法 §9.2：TDD 小循环，每测试方法测单一行为。
# 延续 M1/M2 经验：动画选择抽纯函数（不依赖节点渲染状态），单测直接传布尔值覆盖分支。
#
# 注意：M3 起 player.gd 含 @onready body_sprite 引用，须实例化 player.tscn
# （含 BodySprite 子节点）而非 Player.new()，否则 _ready 报 Node not found。
extends GdUnitTestSuite


# === 测试夹具 ===

## 实例化 player.tscn（含 BodySprite/BodyShape 完整节点树）并加入场景树。
##
## M3 起 player.gd 依赖 @onready body_sprite，纯 Player.new() 无该子节点会报错，
## 故改为实例化场景（遵宪法 §4.2 场景可复用可实例化）。
func _make_player() -> Player:
	var packed: PackedScene = load("res://scenes/player.tscn")
	var player: Player = packed.instantiate()
	player.stats = PlayerStats.new()
	add_child(player)
	# GdUnit4 自动清理：测试结束自动释放，避免泄漏。
	auto_free(player)
	return player


# === 测试用例 ===

## 空中（非地面）无论是否移动都应选 jump 动画（覆盖 M4-1/M4-2 滞空优先）。
func test_pick_jump_when_airborne() -> void:
	var player := _make_player()
	assert_str(player.pick_animation(false, false)).is_equal(&"jump")
	assert_str(player.pick_animation(false, true)).is_equal(&"jump")


## 着地且移动中应选 run 动画（覆盖 M3-3 跑动）。
func test_pick_run_when_grounded_and_moving() -> void:
	var player := _make_player()
	assert_str(player.pick_animation(true, true)).is_equal(&"run")


## 着地且静止应选 idle 动画（覆盖 M3-2 呼吸）。
func test_pick_idle_when_grounded_and_still() -> void:
	var player := _make_player()
	assert_str(player.pick_animation(true, false)).is_equal(&"idle")
