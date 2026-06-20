## 主角控制脚本。
##
## M1 阶段：实现水平移动（加速度/摩擦力模型）+ 基础重力下落。
## 跳跃留待 M2（架构 §15.2）。遵从宪法 §1.4 数据驱动：数值走 PlayerStats。
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
	# 水平移动：读 Input 方向 → 加速度/摩擦力模型。
	var input_dir: float = Input.get_axis(&"move_left", &"move_right")
	velocity.x = compute_horizontal_velocity(velocity.x, input_dir, delta)
	move_and_slide()

# === Public Methods ===

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
