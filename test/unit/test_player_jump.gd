# 主角跳跃判定单元测试（M2）。
#
# 覆盖 player.gd 的 should_jump 纯函数（着地 + 按键判定）。
# 遵从宪法 §9.2：TDD 小循环，每测试方法测单一行为。
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

## 在地面且按下跳跃键 → 应当起跳（覆盖 AC3b 正向用例）。
func test_should_jump_when_grounded_and_jump_pressed() -> void:
	var player := _make_player()
	assert_bool(player.should_jump(true, true)).is_true()


## 在空中（非地面）即使按下跳跃键也不应起跳（覆盖 M2-3 无双跳）。
func test_should_not_jump_when_airborne() -> void:
	var player := _make_player()
	assert_bool(player.should_jump(false, true)).is_false()


## 在地面但未按跳跃键 → 不应起跳（覆盖无输入）。
func test_should_not_jump_when_no_jump_input() -> void:
	var player := _make_player()
	assert_bool(player.should_jump(true, false)).is_false()
