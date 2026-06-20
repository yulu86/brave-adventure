## 主角控制脚本。
##
## M2 阶段：M1 水平移动/重力下落基础上，增量加入跳跃（变速跳跃 + 空中可控 + 非地面不起跳）。
## 跳跃判定散装在主脚本（架构 §4.3）；土狼时间/缓冲留 M6 统一接入。遵从宪法 §1.4 数据驱动：数值走 PlayerStats。
class_name Player
extends CharacterBody2D

# === Exports ===
## 主角数值配置（数据驱动，遵从宪法 §1.4）。
@export var stats: PlayerStats

# === Onready ===
# （M1 占位阶段，无精灵/碰撞引用；场景骨架由 MCP 搭建后逐步接入）

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
