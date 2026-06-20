# 主角水平移动单元测试（M1）。
#
# 覆盖 player.gd 的水平速度计算逻辑（加速度/摩擦力模型）。
# 遵从宪法 §9.2：TDD 小循环，每测试方法测单一行为；浮点用 assert_almost_eq。
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

## 给定正向输入，水平速度应在若干帧内由 0 加速到 move_speed。
func test_accelerates_to_move_speed_with_input() -> void:
	var player := _make_player()
	var stats: PlayerStats = player.stats
	var delta := 1.0 / 60.0
	var vx: float = 0.0
	# 持续施加正向输入，模拟足帧加速。
	for _i in range(30):
		vx = player.compute_horizontal_velocity(vx, 1.0, delta)
	# 加速度模型下，max_speed 是上界，应在数帧内逼近。
	assert_float(vx).is_equal_approx(stats.move_speed, 1.0)


## 松开输入后，水平速度应受摩擦力逐帧衰减至 0（覆盖无输入分支）。
func test_decelerates_to_zero_without_input() -> void:
	var player := _make_player()
	var delta := 1.0 / 60.0
	# 起始给一个满速，模拟"刚松手"。
	var vx: float = player.stats.move_speed
	for _i in range(30):
		vx = player.compute_horizontal_velocity(vx, 0.0, delta)
	# 摩擦力足以在数帧内刹停。
	assert_float(vx).is_equal_approx(0.0, 1.0)


## 输入方向反转时，速度不应超过 move_speed 上界（覆盖反向输入边界）。
func test_speed_capped_at_move_speed() -> void:
	var player := _make_player()
	var stats: PlayerStats = player.stats
	var delta := 1.0 / 60.0
	var vx: float = 0.0
	# 反向持续输入。
	for _i in range(30):
		vx = player.compute_horizontal_velocity(vx, -1.0, delta)
	# 速度应被钳制在 -move_speed，不超过（绝对值不超）。
	assert_float(vx).is_equal_approx(-stats.move_speed, 1.0)
