## 主角控制脚本。
##
## M4 阶段：M3 idle/run 基础上，增量加入跳跃动画（空中优先 jump）。
## 动画选择逻辑散装在主脚本（架构 §4.3）；M5 才迁入状态机。遵从宪法 §1.4 数据驱动：数值走 PlayerStats。
class_name Player
extends CharacterBody2D

# === Constants ===
## 静止/移动动画帧高（idle/run 含持剑高举空间，美术清单附录 A）。
const _FRAME_H_80: int = 80
## 跳跃动画帧高（起势/滞空/落地合并表，无高举空间）。
const _FRAME_H_64: int = 64

# === Exports ===
## 主角数值配置（数据驱动，遵从宪法 §1.4）。
@export var stats: PlayerStats

# === Onready ===
## 身体精灵（AnimatedSprite2D）。
## 帧高差异（80 vs 64）通过 _apply_offset 动态切换 offset 解决（§14.2）。
@onready var body_sprite: AnimatedSprite2D = $BodySprite

# === Lifecycle ===

func _physics_process(delta: float) -> void:
	# 重力（架构 ADR-2：读 ProjectSettings 全局值，不放 PlayerStats）。
	velocity.y += get_gravity().y * delta
	# 跳跃判定：着地且按下跳跃键 → 施加朝上初速度（覆盖 M2-3：非地面不起跳）。
	if should_jump(is_on_floor(), Input.is_action_just_pressed(&"jump")):
		velocity.y = stats.jump_velocity
	# 变速跳跃：松开跳跃键且仍处于上升阶段 → 上升速度乘倍率，实现可控高度（M2-1）。
	if Input.is_action_just_released(&"jump") and velocity.y < 0.0:
		velocity.y *= stats.variable_jump_multiplier
	# 水平移动：读 Input 方向 → 加速度/摩擦力模型（空中同样可控，M2-2）。
	var input_dir: float = Input.get_axis(&"move_left", &"move_right")
	velocity.x = compute_horizontal_velocity(velocity.x, input_dir, delta)
	move_and_slide()
	# 动画选择与方向翻转（M3/M4）：跳跃 > 移动 > 静止，水平速度近零视为静止。
	var moving: bool = abs(velocity.x) > 1.0
	var anim: StringName = pick_animation(is_on_floor(), moving)
	# 仅在动画名变化时调 play（避免每帧重复调用；非循环 jump 播完后停在末帧，
	# 由落地切 is_on_floor()=true 触发切回 idle/run，不会反复重播）。
	if body_sprite.animation != anim:
		body_sprite.play(anim)
	_apply_offset(anim)
	# flip_h 持续更新（空中仍随水平输入翻转，满足 M4-4）。
	if input_dir != 0.0:
		body_sprite.flip_h = input_dir < 0.0

# === Public Methods ===

## 判定是否应当起跳（纯逻辑，可独立单元测试）。
##
## 仅在「着地」且「按下跳跃键」时允许起跳，满足非地面不起跳（M2-3）。[br]
## [param on_floor] 本帧是否着地（来自 [method CharacterBody2D.is_on_floor]）。[br]
## [param jump_pressed] 本帧是否刚按下跳跃键（来自 [method Input.is_action_just_pressed]）。
func should_jump(on_floor: bool, jump_pressed: bool) -> bool:
	return on_floor and jump_pressed

## 根据输入方向计算下一帧水平速度（加速度/摩擦力模型）。
##
## 纯逻辑、可独立单元测试。[br]
## [param current_vx] 当前水平速度。[br]
## [param input_dir] 输入方向（-1.0 / 0.0 / 1.0）。[br]
## [param delta] 帧间隔（秒）。
func compute_horizontal_velocity(current_vx: float, input_dir: float, delta: float) -> float:
	var target_vx: float = input_dir * stats.move_speed
	if input_dir != 0.0:
		# 有输入：朝目标速度加速。
		current_vx = move_toward(current_vx, target_vx, stats.acceleration * delta)
	else:
		# 无输入：受摩擦力减速至 0。
		current_vx = move_toward(current_vx, 0.0, stats.friction * delta)
	return current_vx

## 选择当前应播放的动画名（纯逻辑，可独立单元测试）。
##
## 优先级：空中播 jump（M4-1/M4-2），着地移动播 run（M3-3），着地静止播 idle（M3-2）。[br]
## [param on_floor] 是否着地。[br]
## [param moving] 是否处于水平移动状态（abs(velocity.x) > 阈值）。
func pick_animation(on_floor: bool, moving: bool) -> StringName:
	if not on_floor:
		return &"jump"
	return &"run" if moving else &"idle"

# === Private Methods ===

## 按动画帧高动态对齐 offset 脚底中心（缓解 §14.2 帧尺寸不一致致跳位）。
##
## AnimatedSprite2D.offset 是节点级单一值（无 per-animation offset），
## 故切动画时手动设：idle/run(80) → offset.y=-40；jump(64) → offset.y=-32。
func _apply_offset(anim: StringName) -> void:
	if anim == &"jump":
		body_sprite.offset = Vector2(0, -_FRAME_H_64 / 2)
	else:
		body_sprite.offset = Vector2(0, -_FRAME_H_80 / 2)
